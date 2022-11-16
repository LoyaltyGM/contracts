module loyalty_gm::loyalty_store {
    friend loyalty_gm::loyalty_system;

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object_table::{Self, ObjectTable};

    struct LoyaltyStoreRecord has key, store {
        id: UID,
        record_number: u64,
        loyalty_system: ID,
        creator: address,
    }

    fun init(ctx: &mut TxContext) {
        let table = object_table::new<u64, LoyaltyStoreRecord>(ctx);
        transfer::share_object(table)
    }

    public(friend) fun new_record(store: &mut ObjectTable<u64, LoyaltyStoreRecord>, object_id: ID, ctx: &mut TxContext) {  
        let n = object_table::length(store);

        let record = LoyaltyStoreRecord {
            id: object::new(ctx),
            record_number: n,
            loyalty_system: object_id,
            creator: tx_context::sender(ctx),
        };

        object_table::add(store, n, record);
    }

    public fun get_total_records(store: &ObjectTable<u64, LoyaltyStoreRecord>): u64 {
        object_table::length(store)
    }

    public fun get_record_by_key(store: &ObjectTable<u64, LoyaltyStoreRecord>, key: u64): &LoyaltyStoreRecord {
        object_table::borrow(store, key)
    }
}