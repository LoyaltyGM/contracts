module loyalty_gm::loyalty_token {
    use std::string::{Self, String};

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::url::{Url};
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use sui::math::{Self};

    use loyalty_gm::loyalty_system::{Self, LoyaltySystem};
    use loyalty_gm::user_store::{Self};
    use loyalty_gm::reward_store::{Self};

    // ======== Constants =========

    const INITIAL_LVL: u64 = 0;
    const INITIAL_XP: u64 = 0;
    const LVL_DIVIDER: u64 = 50;

    // ======== Error codes =========

    const ENotUniqueAddress: u64 = 0;
    const ETooManyMint: u64 = 1;
    const ENoClaimableXp: u64 = 2;
    const EAdminOnly: u64 = 3;
    const EInvalidTokenStore: u64 = 4;
    const EInvalidLvl: u64 = 4;

    // ======== Structs =========

    /// Loyalty NFT.
    struct LoyaltyToken has key, store {
        id: UID,
        loyalty_system: ID,
        name: String,
        description: String,
        url: Url,
        
        lvl: u64,
        xp: u64,
        xp_to_next_lvl: u64,
    }

    // ======== Events =========

    struct MintTokenEvent has copy, drop {
        object_id: ID,
        loyalty_system:ID,
        minter: address,
        name: string::String,
    }

    struct ClaimXpEvent has copy, drop {
        token_id: ID,
        claimer: address,
        claimed_xp: u64,
    }


    // ======= Public functions =======

    public entry fun mint(
        ls: &mut LoyaltySystem,
        ctx: &mut TxContext
    ) {
        loyalty_system::increment_total_minted(ls);

        let nft = LoyaltyToken {
            id: object::new(ctx),
            loyalty_system: object::id(ls),
            name: *loyalty_system::get_name(ls),
            description: *loyalty_system::get_description(ls),
            url: *loyalty_system::get_url(ls),
            lvl: INITIAL_LVL,
            xp: INITIAL_XP,
            xp_to_next_lvl: get_xp_to_next_lvl(INITIAL_LVL, INITIAL_XP),
        };
        let sender = tx_context::sender(ctx);

        emit(MintTokenEvent {
            object_id: object::id(&nft),
            loyalty_system: object::id(ls),
            minter: sender,
            name: nft.name,
        });

        user_store::add_user(loyalty_system::get_mut_user_store(ls), object::id(&nft), ctx);
        transfer::transfer(nft, sender);
    }

    public entry fun claim_exp (
        ls: &mut LoyaltySystem,
        token: &mut LoyaltyToken, 
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let claimable_xp = user_store::get_user_xp(loyalty_system::get_user_store(ls), sender);
        assert!(claimable_xp > 0, ENoClaimableXp);

        emit(ClaimXpEvent {
            token_id: object::id(token),
            claimer: sender,
            claimed_xp: claimable_xp,
        });

        user_store::reset_user_xp(loyalty_system::get_mut_user_store(ls), sender);

        update_token_stats(claimable_xp, ls, token);
    }

    public entry fun claim_reward (
        ls: &mut LoyaltySystem,
        token: &mut LoyaltyToken, 
        reward_lvl: u64,
        ctx: &mut TxContext
    ) {
        assert!(token.lvl >= reward_lvl, EInvalidLvl);
        reward_store::claim_reward(loyalty_system::get_mut_reward(ls, reward_lvl), ctx);
    }

    // ======== Admin Functions =========

    // ======= Private and Utility functions =======

    fun update_token_stats(
        xp_to_add: u64,
        ls: &mut LoyaltySystem,
        token: &mut LoyaltyToken,
    ) {
        let new_xp = token.xp + xp_to_add;
        let new_lvl = get_lvl_by_xp(new_xp);

        token.xp = new_xp;
        token.xp_to_next_lvl = get_xp_to_next_lvl(new_lvl, new_xp);

        let max_lvl = loyalty_system::get_max_lvl(ls);
        token.lvl = if (new_lvl <= max_lvl) new_lvl else max_lvl;
    }
    
    fun get_lvl_by_xp(xp: u64): u64 {
        math::sqrt(xp/LVL_DIVIDER)
    }

    fun get_xp_by_lvl(lvl: u64): u64 {
        lvl * lvl * LVL_DIVIDER
    }

    fun get_xp_to_next_lvl(lvl: u64, xp: u64): u64 {
        get_xp_by_lvl(lvl + 1) - xp
    }
}