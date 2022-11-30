module loyalty_gm::task_store {
    // id to task
    // ======== store: VecMap<u64, Task> =========
    
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use std::string::{Self, String};
    use std::vector::{Self};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};

    // ======== Constants =========

    const INITIAL_EXP: u64 = 0;
    const BASIC_REWARD_EXP: u64 = 5;

    // ======== Structs =========

    struct Task has store, drop {
        id: u64,
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

    public(friend) fun empty(): VecMap<u64, Task> {  
        vec_map::empty<u64, Task>()
    }

    public(friend) fun add_task(
        store: &mut VecMap<u64, Task>,
        id: u64, 
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
        let string_args = vector::empty<String>();
        vector::reverse(&mut arguments);
        while(!vector::is_empty(&arguments)) {
            vector::push_back(&mut string_args, string::utf8(vector::pop_back(&mut arguments)))
        };

        let task = Task {
            id,
            name: string::utf8(name),
            description: string::utf8(description),
            reward_exp,
            package_id,
            module_name: string::utf8(module_name),
            function_name: string::utf8(function_name),
            arguments: vector::empty<String>(),
            start,
            end,
        };
        vec_map::insert(store, id, task);
    }

    public(friend) fun remove_task(store: &mut VecMap<u64, Task>, id: u64) {
        vec_map::remove(store, &id);
    }
}