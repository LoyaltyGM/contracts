module loyalty_gm::user_store {
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object_table::{Self, ObjectTable};

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

    public(friend) fun create_store(ctx: &mut TxContext): ID {  
        let store = object_table::new<address, UserData>(ctx);
        let id = object::id(&store);
        transfer::share_object(store);
        id
    }

    public(friend) fun add_new_data(
        store: &mut ObjectTable<address, UserData>, 
        token_id: ID,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let data = UserData {
            id: object::new(ctx),
            token_id: token_id,
            owner: sender,
            claimable_exp: INITIAL_EXP,
        };

        object_table::add(store, sender, data)
    }

    // Not currently used anywhere
    public(friend) fun update_data_exp(store: &mut ObjectTable<address, UserData>, owner: address) {
        let user_data = object_table::borrow_mut<address, UserData>(store, owner);
        user_data.claimable_exp = user_data.claimable_exp + BASIC_REWARD_EXP;
    }

    public(friend) fun reset_data_exp(store: &mut ObjectTable<address, UserData>, owner: address) {
        let user_data = object_table::borrow_mut<address, UserData>(store, owner);
        user_data.claimable_exp = INITIAL_EXP;
    }

    public fun get_store_size(store: &ObjectTable<ID, UserData>): u64 {
        object_table::length(store)
    }

    public fun get_user_data(store: &ObjectTable<address, UserData>, owner: address): &UserData {
        object_table::borrow(store, owner)
    }

    public fun user_exists(table: &ObjectTable<address, UserData>, owner: address): bool {
        object_table::contains(table, owner)
    }

    public fun get_data_exp(table: &ObjectTable<address, UserData>, owner: address): u64 {
        let user_data = object_table::borrow<address, UserData>(table, owner);
        user_data.claimable_exp
    }
}