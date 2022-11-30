module loyalty_gm::task_store {
    // name to task
    // ======== store: VecMap<String, Task> =========
    
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use std::string::{Self, String};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};

    // ======== Constants =========

    const INITIAL_EXP: u64 = 0;
    const BASIC_REWARD_EXP: u64 = 5;

    // ======== Structs =========

    struct Task has store, drop {
        name: String,
        description: String,
        reward_exp: u64,
        // Package
        // Module
        // Function
        // Argument
        // timestamp
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
    ) {
        let name = string::utf8(name);
        let task = Task {
            name,
            description: string::utf8(description),
            reward_exp,
        };
        vec_map::insert(store, name, task);
    }

    public(friend) fun remove_task(store: &mut VecMap<String, Task>, name: vector<u8>) {
        vec_map::remove(store, &string::utf8(name));
    }
}