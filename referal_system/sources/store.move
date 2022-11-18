module referal_system::store {
    friend referal_system::token;
    
    use sui::object::{Self, UID, ID};
    use sui::object_table::{Self, ObjectTable};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // ======== Constants =========

    const INITIAL_EXP: u64 = 0;
    const REF_REWARD_EXP: u64 = 5;
    
    // ======== Error codes =========

    // ======== Structs =========

    struct UserData has key, store {
        id: UID,
        token_id: ID,
        owner: address,
        // reset when claim
        claimable_exp: u64,
    }

    // ======== Events =========

    // ======= INITIALIZATION =======

    fun init(ctx: &mut TxContext){
        let store = object_table::new<address, UserData>(ctx);
        transfer::share_object(store);
    }

    // ======= Public functions =======

    public fun user_exists(table: &ObjectTable<address, UserData>, owner: address): bool {
        object_table::contains(table, owner)
    }

    public fun get_data_exp(table: &ObjectTable<address, UserData>, owner: address): u64 {
        let user_data = object_table::borrow<address, UserData>(table, owner);
        user_data.claimable_exp
    }

    public(friend) fun add_new_data(
        table: &mut ObjectTable<address, UserData>, 
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

        object_table::add(table, sender, data)
    }

    public(friend) fun update_data_exp(table: &mut ObjectTable<address, UserData>, owner: address) {
        let user_data = object_table::borrow_mut<address, UserData>(table, owner);
        user_data.claimable_exp = user_data.claimable_exp + REF_REWARD_EXP;
    }

    public(friend) fun reset_data_exp(table: &mut ObjectTable<address, UserData>, owner: address) {
        let user_data = object_table::borrow_mut<address, UserData>(table, owner);
        user_data.claimable_exp = INITIAL_EXP;
    }
}