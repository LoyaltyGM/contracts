module loyalty_gm::system_store {
    friend loyalty_gm::loyalty_system;

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{TxContext};
    use std::vector::{Self};

    // ======== Structs =========

    struct SystemStore has key {
        id: UID,
        systems: vector<ID>,
    }

    fun init(ctx: &mut TxContext) {
        let store = SystemStore {
            id: object::new(ctx),
            systems: vector::empty<ID>()
        };

        transfer::share_object(store)
    }

    // ======== Public functions =========

    public(friend) fun add_system(store: &mut SystemStore, loyalty_system_id: ID, _: &mut TxContext) {  
        vector::push_back(&mut store.systems, loyalty_system_id);
    }

    public fun length(store: &SystemStore): u64 {
        vector::length(&store.systems)
    }

    public fun contains(store: &SystemStore, key: ID): bool {
        vector::contains(&store.systems, &key)
    }

    public fun borrow(store: &SystemStore, i: u64): ID {
        *vector::borrow(&store.systems, i)
    }
}