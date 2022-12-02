module loyalty_gm::task_store {
    // id to task
    // ======== store: VecMap<String, Task> =========
    
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use std::string::{Self, String};

    use sui::object::{Self, ID};
    use sui::vec_map::{Self, VecMap};
    use sui::tx_context::{TxContext};


    use loyalty_gm::utils::{Self};

    // ======== Constants =========

    const INITIAL_EXP: u64 = 0;
    const BASIC_REWARD_EXP: u64 = 5;
    const MAX_TASKS: u64 = 100;

    // ======== Error codes =========

    const EMaxTasksReached: u64 = 0;

    // ======== Structs =========

    struct Task has store, drop {
        id: ID,
        name: String,
        description: String,
        reward_exp: u64,
        package_id: ID,
        module_name: String,
        function_name: String,
        arguments: vector<String>,
    }

    // ======== Public functions =========

    // public entry start_task(name,)

    
    // ======== Friend functions =========

    public(friend) fun empty(): VecMap<ID, Task> {  
        vec_map::empty<ID, Task>()
    }

    public(friend) fun add_task(
        store: &mut VecMap<ID, Task>,
        name: vector<u8>,
        description: vector<u8>,
        reward_exp: u64, 
        package_id: ID,
        module_name: vector<u8>,
        function_name: vector<u8>,
        arguments: vector<vector<u8>>,
        ctx: &mut TxContext
    ) {
        assert!(vec_map::size(store) <= MAX_TASKS, EMaxTasksReached);
        
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        object::delete(uid);

        let task = Task {
            id,
            name: string::utf8(name),
            description: string::utf8(description),
            reward_exp,
            package_id,
            module_name: string::utf8(module_name),
            function_name: string::utf8(function_name),
            arguments: utils::to_string_vec(arguments),
        };
        vec_map::insert(store, id, task);
    }

    public(friend) fun remove_task(store: &mut VecMap<ID, Task>, task_id: ID) {
        vec_map::remove(store, &task_id);
    }

    public fun get_task_reward(store: &VecMap<ID, Task>, task_id: &ID): u64 {
       vec_map::get(store, task_id).reward_exp
    }
}