module loyalty_gm::referal_token {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::object_table::{Self, ObjectTable};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use std::option::{Self, Option, some};

    // ======== Constants =========

    // TODO: deploy store to another package
    const NAME: vector<u8> = b"LoyaltyGM";
    const DESCRIPTION: vector<u8> = b"SBT for Loyalty Rewards Platform on Sui Blockchain";
    const URL: vector<u8> = b"ipfs://QmbtwaZubBFDXTvZ3S3ytdByaU85AzaY3yE8epVuhNkRZh";

    const INITIAL_REF_COUNTER: u64 = 0;
    const INITIAL_EXP: u64 = 0;
    const REF_REWARD_EXP: u64 = 5;
    
    // ======== Error codes =========

    const ENotUniqueAddress: u64 = 0;
    const EInvalidReferal: u64 = 1;
    const ENoClaimableExp: u64 = 2;

    // ======== Structs =========

    /// Loyalty Token.
    struct Token has key {
        id: UID,
        name: String,
        description: String,
        url: String,
        // minted with referal or not
        ref_id: Option<address>,
        // number of nfts
        ref_counter: u64,
        // current points
        current_exp: u64,
    }

    struct UserData has key, store {
        id: UID,
        token_id: ID,
        owner: address,
        // reset when claim
        claimable_exp: u64,
    }

    // ======== Events =========

    // EVENT MINT
    struct MintTokenEvent has copy, drop {
        object_id: ID,
        minter: address,
        name: string::String,
    }

    // ======= INITIALIZATION =======

    fun init(ctx: &mut TxContext){
        let store = object_table::new<address, UserData>(ctx);
        transfer::share_object(store);
    }

    // ======= Public functions =======

    public entry fun claim_exp (
        token: &mut Token, 
        store: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let claimable_exp = get_data_exp(store, sender);

        assert!(claimable_exp > 0, ENoClaimableExp);

        reset_data_exp(store, sender);

        update_token_ref_counter(token);
        update_token_exp(claimable_exp, token);
    }

    public entry fun mint(
        store: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        assert!(object_table::contains(store, tx_context::sender(ctx)) == false, ENotUniqueAddress);

        mint_internal(option::none(), store, ctx);
    }

    public entry fun mint_with_ref (
        ref_address: address,
        store: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) != ref_address, EInvalidReferal);

        mint_internal(some(ref_address), store, ctx);
        
        if (object_table::contains(store, ref_address)) {
            update_data_exp(store, ref_address)
        };
    }

    // ======= Private and Utility functions =======

    fun mint_internal (
        ref_id: Option<address>,
        store: &mut ObjectTable<address, UserData>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);

        let nft = Token {
            id: object::new(ctx),
            name: string::utf8(NAME),
            description: string::utf8(DESCRIPTION),
            url: string::utf8(URL),
            ref_id: ref_id,
            ref_counter: INITIAL_REF_COUNTER,
            current_exp: INITIAL_EXP,
        };
        
        emit(MintTokenEvent {
            object_id: object::id(&nft),
            minter: sender,
            name: nft.name,
        });

        let data = UserData {
            id: object::new(ctx),
            token_id: object::id(&nft),
            owner: sender,
            claimable_exp: INITIAL_EXP,
        };

        transfer::transfer(nft, sender);
        object_table::add(store, sender, data)
    }

    // work with token

    fun update_token_exp(exp_to_add: u64, token: &mut Token) {
        token.current_exp = token.current_exp + exp_to_add;
    }

    fun update_token_ref_counter(token: &mut Token) {
        token.ref_counter = token.ref_counter + 1;
    }

    // work with user data table

    fun get_data_exp(store: &ObjectTable<address, UserData>, owner: address): u64 {
        let user_data = object_table::borrow<address, UserData>(store, owner);
        user_data.claimable_exp
    }

    fun update_data_exp(store: &mut ObjectTable<address, UserData>, owner: address) {
        let user_data = object_table::borrow_mut<address, UserData>(store, owner);
        user_data.claimable_exp = user_data.claimable_exp + REF_REWARD_EXP;
    }

    fun reset_data_exp(store: &mut ObjectTable<address, UserData>, owner: address) {
        let user_data = object_table::borrow_mut<address, UserData>(store, owner);
        user_data.claimable_exp = INITIAL_EXP;
    }
}