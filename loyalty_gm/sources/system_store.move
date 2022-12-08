module loyalty_gm::system_store {
    friend loyalty_gm::loyalty_system;

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{TxContext};
    use std::vector::{Self};

    // ======== Structs =========
    struct SYSTEM_STORE has drop {}

    struct SystemStore<phantom T> has key {
        id: UID,
        systems: vector<ID>,
    }

    fun init(_: SYSTEM_STORE, ctx: &mut TxContext) {
        let store = SystemStore<SYSTEM_STORE> {
            id: object::new(ctx),
            systems: vector::empty<ID>()
        };

        transfer::share_object(store)
    }

    // ======== Public functions =========

    public(friend) fun add_system(store: &mut SystemStore<SYSTEM_STORE>, loyalty_system_id: ID, _: &mut TxContext) {  
        vector::push_back(&mut store.systems, loyalty_system_id);
    }

    public fun length(store: &SystemStore<SYSTEM_STORE>): u64 {
        vector::length(&store.systems)
    }

    public fun contains(store: &SystemStore<SYSTEM_STORE>, key: ID): bool {
        vector::contains(&store.systems, &key)
    }

    public fun borrow(store: &SystemStore<SYSTEM_STORE>, i: u64): ID {
        *vector::borrow(&store.systems, i)
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init(SYSTEM_STORE {}, ctx)
    }
}