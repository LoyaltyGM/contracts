module loyalty_gm::reward_store {
    // level to reward
    // ======== store: VecMap<u64, Reward> =========
    
    friend loyalty_gm::loyalty_system;
    friend loyalty_gm::loyalty_token;

    use std::string::{Self, String};

    use sui::vec_map::{Self, VecMap};

    // ======== Constants =========

    const INITIAL_XP: u64 = 0;
    const BASIC_REWARD_XP: u64 = 5;

    // ======== Structs =========

    struct Reward has store, drop {
        level: u8,
        description: String,
    }

    // ======== Public functions =========

    public(friend) fun empty(): VecMap<u8, Reward> {  
        vec_map::empty<u8, Reward>()
    }

    public(friend) fun add_reward(store: &mut VecMap<u8, Reward>, level: u8, description: vector<u8>) {
        let reward_info = Reward {
            level, 
            description: string::utf8(description)
        };
        vec_map::insert(store, level, reward_info);
    }

    public(friend) fun remove_reward(store: &mut VecMap<u8, Reward>, level: u8) {
        vec_map::remove(store, &level);
    }
}