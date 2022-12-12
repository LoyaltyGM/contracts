module loyalty_gm::user_store {
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};

    // ======== Constants =========

    const INITIAL_EXP: u64 = 0;
    const BASIC_REWARD_EXP: u64 = 5;

    // ======== Structs =========

    struct UserData has key, store {
        id: UID,
        token_id: ID,
        owner: address,
        // reset when claim
        claimable_exp: u64,
    }

    // ======== Public functions =========

    public(friend) fun create_store(ctx: &mut TxContext): Table<address, UserData> {
        table::new<address, UserData>(ctx)
    }

    public(friend) fun add_new_data(
        store: &mut Table<address, UserData>,
        token_id: ID,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let data = UserData {
            id: object::new(ctx),
            token_id,
            owner: sender,
            claimable_exp: INITIAL_EXP,
        };

        table::add(store, sender, data)
    }

    // Not currently used anywhere
    public(friend) fun update_data_exp(store: &mut Table<address, UserData>, owner: address) {
        let user_data = table::borrow_mut<address, UserData>(store, owner);
        user_data.claimable_exp = user_data.claimable_exp + BASIC_REWARD_EXP;
    }

    public(friend) fun reset_data_exp(store: &mut Table<address, UserData>, owner: address) {
        let user_data = table::borrow_mut<address, UserData>(store, owner);
        user_data.claimable_exp = INITIAL_EXP;
    }

    public fun get_store_size(store: &Table<ID, UserData>): u64 {
        table::length(store)
    }

    public fun get_user_data(store: &Table<address, UserData>, owner: address): &UserData {
        table::borrow(store, owner)
    }

    public fun user_exists(table: &Table<address, UserData>, owner: address): bool {
        table::contains(table, owner)
    }

    public fun get_data_exp(table: &Table<address, UserData>, owner: address): u64 {
        let user_data = table::borrow<address, UserData>(table, owner);
        user_data.claimable_exp
    }
}