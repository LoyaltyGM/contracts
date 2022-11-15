module loyalty_gm::loyalty_store {
    friend loyalty_gm::loyalty_system;

    use sui::object::{ID};
    use sui::transfer;
    use sui::tx_context::{TxContext};
    use sui::table::{Self, Table};


    struct LoyaltyStoreRecord has store {
        loyalty_system: ID,
    }

    fun init(ctx: &mut TxContext) {
        let table = table::new<u64, LoyaltyStoreRecord>(ctx);
        transfer::share_object(table)
    }

    public(friend) fun new_record(table:  &mut Table<u64, LoyaltyStoreRecord>, object_id: ID) {  
        let n = table::length(table) + 1;

        let record = LoyaltyStoreRecord {
            loyalty_system: object_id,
        };

        table::add(table, n, record);
    }
}