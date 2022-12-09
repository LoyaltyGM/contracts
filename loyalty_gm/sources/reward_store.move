module loyalty_gm::reward_store {
    // level to reward
    // ======== store: VecMap<u64, Reward> =========
    
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use std::string::{Self, String};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::table::{Self};
    use sui::dynamic_object_field as dof;
    use sui::balance::{Self, Balance};
    use sui::event::{emit};

    // ======== Constants =========

    const INITIAL_XP: u64 = 0;
    const BASIC_REWARD_XP: u64 = 5;
    const REWARD_RECIPIENTS_KEY: vector<u8> = b"reward_recipients";

    // ======== Constants =========

    const EInvalidSupply: u64 = 0;
    const ERewardPoolExceeded: u64 = 1;
    const EAlreadyClaimed: u64 = 2;

    // ======== Structs =========

    struct Reward has key, store {
        id: UID,
        level: u64,
        url: Url,
        description: String,
        reward_pool: Balance<SUI>,
        reward_supply: u64,
        reward_per_user: u64,
    }

    // ======== Events =========

    struct CreateRewardEvent has copy, drop {
        /// Object ID of the Reward
        reward_id: ID,
        /// Lvl of the Reward
        lvl: u64,
        /// Description of the Reward
        description: string::String,
    }


    // ======== Public functions =========

    public(friend) fun empty(): VecMap<u64, Reward> {  
        vec_map::empty<u64, Reward>()
    }

    public(friend) fun add_reward(
        store: &mut VecMap<u64, Reward>,
        level: u64, 
        url: vector<u8>,
        description: vector<u8>,
        reward_pool: Coin<SUI>,
        reward_supply: u64,
        ctx: &mut TxContext
    ) {
        let balance = coin::into_balance(reward_pool);
        let balance_val = balance::value(&balance); 
        assert!(balance_val % reward_supply == 0, EInvalidSupply);

        let reward = Reward {
            id: object::new(ctx),
            level, 
            url: url::new_unsafe_from_bytes(url),
            description: string::utf8(description),
            reward_pool: balance,
            reward_supply,
            reward_per_user: balance_val / reward_supply,
        };

        emit(CreateRewardEvent {
            reward_id: object::id(&reward),
            lvl: reward.level,
            description: reward.description,
        });

        dof::add(&mut reward.id, REWARD_RECIPIENTS_KEY, table::new<address, bool>(ctx));
        vec_map::insert(store, level, reward);
    }

    public(friend) fun remove_reward(store: &mut VecMap<u64, Reward>, level: u64, ctx: &mut TxContext) {
        let (_, reward) =  vec_map::remove(store, &level);

        let sui_amt = balance::value(&reward.reward_pool);
        transfer::transfer(
            coin::take(&mut reward.reward_pool, sui_amt, ctx), 
            tx_context::sender(ctx)
        ); 

        delete_reward(reward); 
    }

    public(friend) fun claim_reward(
        reward: &mut Reward,
        ctx: &mut TxContext
    ) {
        check_claimed(reward, ctx);

        let pool_amt = balance::value(&reward.reward_pool);
        assert!(pool_amt >= reward.reward_per_user, ERewardPoolExceeded);

        set_reward_claimed(reward, ctx);

        transfer::transfer(
            coin::take(&mut reward.reward_pool, reward.reward_per_user, ctx), 
            tx_context::sender(ctx)
        ); 
    }

    // ======== Private functions =========

    fun set_reward_claimed(reward: &mut Reward, ctx: &mut TxContext) {
        table::add<address, bool>(
            dof::borrow_mut(&mut reward.id, REWARD_RECIPIENTS_KEY), 
            tx_context::sender(ctx),
            true
        );
    }

    fun check_claimed(reward: &Reward, ctx: &mut TxContext) {
        assert!(
            !table::contains<address, bool>(
                dof::borrow(&reward.id, REWARD_RECIPIENTS_KEY), 
                tx_context::sender(ctx)
            ), 
            EAlreadyClaimed
        );
    }

    fun delete_reward(reward: Reward) {
        let Reward {
            id, 
            description:_, 
            level:_, 
            url:_, 
            reward_pool, 
            reward_supply:_,
            reward_per_user:_,
        } = reward;
        balance::destroy_zero(reward_pool);
        object::delete(id);
    }
}