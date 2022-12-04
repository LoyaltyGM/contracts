module loyalty_gm::user_store {
    // ======== store: Table<address, UserData> =========

    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use sui::object::{ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::vec_set::{Self, VecSet};

    // ======== Constants =========

    const INITIAL_XP: u64 = 0;

    // ======== Errors =========

    const ETaskAlreadyDone: u64 = 0;
    const ETaskNotStarted: u64 = 1;

    // ======== Structs =========

    struct User has store {
        token_id: ID,
        owner: address,
        active_tasks: VecSet<ID>,
        done_tasks: VecSet<ID>,
        // resetting
        // rewards:
        claimable_xp: u64,
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
            token_id,
            active_tasks: vec_set::empty(),
            done_tasks: vec_set::empty(),
            owner,
            claimable_xp: INITIAL_XP,
        };

        table::add(store, owner, data)
    }

    public(friend) fun update_user_xp(
        store: &mut Table<address, User>, 
        owner: address,
        reward_xp: u64
    ) {
        let user_data = table::borrow_mut<address, User>(store, owner);
        user_data.claimable_xp = user_data.claimable_xp + reward_xp;
    }

    public(friend) fun reset_user_xp(store: &mut Table<address, User>, owner: address) {
        let user_data = table::borrow_mut<address, User>(store, owner);
        user_data.claimable_xp = INITIAL_XP;
    }

    public(friend) fun start_task(store: &mut Table<address, User>, task_id: ID, owner: address) {
        let user_data = table::borrow_mut<address, User>(store, owner);
        assert!(!vec_set::contains(&user_data.done_tasks, &task_id), ETaskAlreadyDone);
        vec_set::insert(&mut user_data.active_tasks, task_id)
    }

    public(friend) fun finish_task(
        store: &mut Table<address, User>, 
        task_id: ID, 
        owner: address,
        reward_xp: u64
    ) {
        let user_data = table::borrow_mut<address, User>(store, owner);

        assert!(vec_set::contains(&user_data.active_tasks, &task_id), ETaskNotStarted);
        assert!(!vec_set::contains(&user_data.done_tasks, &task_id), ETaskAlreadyDone);

        vec_set::remove(&mut user_data.active_tasks, &task_id);
        vec_set::insert(&mut user_data.done_tasks, task_id);

        update_user_xp(store, owner, reward_xp)
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

    public fun get_user_xp(table: &Table<address, User>, owner: address): u64 {
        let user_data = table::borrow<address, User>(table, owner);
        user_data.claimable_xp
    }
}