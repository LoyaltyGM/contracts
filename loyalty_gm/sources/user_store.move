module loyalty_gm::user_store {
    // ======== store: Table<address, UserData> =========

    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};

    // ======== Constants =========

    const INITIAL_EXP: u64 = 0;
    const BASIC_REWARD_EXP: u64 = 5;

    // ======== Structs =========

    struct User has key, store {
        id: UID,
        token_id: ID,
        owner: address,
        // reset when claim
        claimable_exp: u64,
    }

    // ======== Public functions =========

    public(friend) fun new(ctx: &mut TxContext): Table<address, User> {  
        table::new<address, User>(ctx)
    }

    public(friend) fun add_user(
        store: &mut Table<address, User>, 
        token_id: ID,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        let data = User {
            id: object::new(ctx),
            token_id,
            owner,
            claimable_exp: INITIAL_EXP,
        };

        table::add(store, owner, data)
    }

    // Not currently used anywhere
    public(friend) fun update_user_exp(store: &mut Table<address, User>, owner: address) {
        let user_data = table::borrow_mut<address, User>(store, owner);
        user_data.claimable_exp = user_data.claimable_exp + BASIC_REWARD_EXP;
    }

    public(friend) fun reset_user_exp(store: &mut Table<address, User>, owner: address) {
        let user_data = table::borrow_mut<address, User>(store, owner);
        user_data.claimable_exp = INITIAL_EXP;
    }

    public fun size(store: &Table<ID, User>): u64 {
        table::length(store)
    }

    public fun get_user(store: &Table<address, User>, owner: address): &User {
        table::borrow(store, owner)
    }

    public fun user_exists(table: &Table<address, User>, owner: address): bool {
        table::contains(table, owner)
    }

    public fun get_user_exp(table: &Table<address, User>, owner: address): u64 {
        let user_data = table::borrow<address, User>(table, owner);
        user_data.claimable_exp
    }
}