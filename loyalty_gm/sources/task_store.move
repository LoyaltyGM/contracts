module loyalty_gm::task_store {
    // id to task
    // ======== store: VecMap<String, Task> =========
    
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use std::string::{Self, String};

    use sui::object::{ID};
    use sui::vec_map::{Self, VecMap};

    use loyalty_gm::utils::{Self};

    // ======== Constants =========

    const INITIAL_EXP: u64 = 0;
    const BASIC_REWARD_EXP: u64 = 5;
    const MAX_TASKS: u64 = 100;

    // ======== Error codes =========

    const EMaxTasksReached: u64 = 0;

    // ======== Structs =========

    struct Task has store, drop {
        name: String,
        description: String,
        reward_exp: u64,
        package_id: ID,
        module_name: String,
        function_name: String,
        arguments: vector<String>,
        // timestamp
        start: u64,
        end: u64,
    }

    // ======== Public functions =========

    // public entry start_task(name,)

    
    // ======== Friend functions =========

    public(friend) fun empty(): VecMap<String, Task> {  
        vec_map::empty<String, Task>()
    }

    public(friend) fun add_task(
        store: &mut VecMap<String, Task>,
        name: vector<u8>,
        description: vector<u8>,
        reward_exp: u64, 
        package_id: ID,
        module_name: vector<u8>,
        function_name: vector<u8>,
        arguments: vector<vector<u8>>,
        start: u64,
        end: u64,
    ) {
        assert!(vec_map::size(store) <= MAX_TASKS, EMaxTasksReached);
        
        let name_key = string::utf8(name);
        let task = Task {
            name: name_key,
            description: string::utf8(description),
            reward_exp,
            package_id,
            module_name: string::utf8(module_name),
            function_name: string::utf8(function_name),
            arguments: utils::to_string_vec(arguments),
            start,
            end,
        };
        vec_map::insert(store, name_key, task);
    }

    public(friend) fun remove_task(store: &mut VecMap<String, Task>, name_key: vector<u8>) {
        vec_map::remove(store, &string::utf8(name_key));
    }
}