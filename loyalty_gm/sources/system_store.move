module loyalty_gm::system_store {
    friend loyalty_gm::loyalty_system;

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object_table::{Self, ObjectTable};

    // ======== Structs =========

    struct LoyaltySystemData has key, store {
        id: UID,
        loyalty_system: ID,
        creator: address,
    }

    fun init(ctx: &mut TxContext) {
        // Only one system per package!
        // It contains all created Loyalty Systems
        let table = object_table::new<ID, LoyaltySystemData>(ctx);
        transfer::share_object(table)
    }

    // ======== Public functions =========

    public(friend) fun add_system(store: &mut ObjectTable<ID, LoyaltySystemData>, loyalty_system_id: ID, ctx: &mut TxContext) {  
        let record = LoyaltySystemData {
            id: object::new(ctx),
            loyalty_system: loyalty_system_id,
            creator: tx_context::sender(ctx),
        };

        object_table::add(store, loyalty_system_id, record);
    }

    public fun get_store_size(store: &ObjectTable<ID, LoyaltySystemData>): u64 {
        object_table::length(store)
    }

    public fun get_record_by_key(store: &ObjectTable<ID, LoyaltySystemData>, loyalty_system_id: ID): &LoyaltySystemData {
        object_table::borrow(store, loyalty_system_id)
    }
}