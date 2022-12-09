module loyalty_gm::utils {
    use std::string::{Self, String};
    use std::vector::{Self};

    // ======== Constants =========

    // ======== Structs =========

    // ======== Public functions =========

    /**
        Converts a vector of u8 vectors to a vector of strings
    */
    public fun to_string_vec(args: vector<vector<u8>>): vector<String> {
        let string_args = vector::empty<String>();
        vector::reverse(&mut args);

        while(!vector::is_empty(&args)) {
            vector::push_back(&mut string_args, string::utf8(vector::pop_back(&mut args)))
        };

        string_args
    }
    
    // ======== Friend functions =========
}