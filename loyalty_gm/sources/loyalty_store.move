module loyalty_gm::loyalty_store {
    friend loyalty_gm::loyalty_system;

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_object_field as dof;
    // use sui::table::{Self, Table};

    struct LoyaltyStore has key {
        id: UID,
        total_records: u64
    }

    struct LoyaltyStoreRecord has key, store {
        id: UID,
        record_number: u64,
        loyalty_system: ID,
        creator: address,
    }

    fun init(ctx: &mut TxContext) {
        // Table implenemtation
        // let table = table::new<u64, LoyaltyStoreRecord>(ctx);
        // transfer::share_object(table)

        transfer::share_object(LoyaltyStore {
            id: object::new(ctx),
            total_records: 0,
        })
    }

    public(friend) fun new_record(store: &mut LoyaltyStore, object_id: ID, ctx: &mut TxContext) {  
        // Table implementation
        // let n = table::length(table) + 1;
        // let record = LoyaltyStoreRecord {
        //     loyalty_system: object_id,
        // };
        // table::add(table, n, record);

        let n = store.total_records + 1;

        store.total_records = n;

        let record = LoyaltyStoreRecord {
            id: object::new(ctx),
            record_number: n,
            loyalty_system: object_id,
            creator: tx_context::sender(ctx),
        };

        dof::add(&mut store.id, n, record);
    }
}