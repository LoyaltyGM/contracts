module loyalty_gm::referal_token {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::object_table::{Self, ObjectTable};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};

    // CONST 
    const NAME: vector<u8> = b"LoyaltyGM";
    const DESCRIPTION: vector<u8> = b"SBT for Loyalty Rewards Platform on Sui Blockchain";
    const URL: vector<u8> = b"ipfs://QmbtwaZubBFDXTvZ3S3ytdByaU85AzaY3yE8epVuhNkRZh";
    const CURRENT_POINTS: u64 = 0;
    const ALREADY_MINTED: u64 = 0;
    const REF_EXP_POINTS: u64 = 5;
    
    // ERROR 
    const ENotUniqueAddress: u64 = 0;
    const EInvalidReferal: u64 = 1;


    struct TokenData has key, store {
        id: UID,
        token_id: ID,
        owner: address,
        // current points
        current_points_xp: u64,
        // number of nfts
        counter: u64,
    }

    /// Loyalty Token.
    struct Token has key {
        id: UID,
        name: String,
        description: String,
        url: String,
    }

    // EVENT MINT
    struct MintTokenEvent has copy, drop {
        object_id: ID,
        minter: address,
        name: string::String,
    }

    fun init(ctx: &mut TxContext){
        let store = object_table::new<address, TokenData>(ctx);
        transfer::share_object(store);
    }

    public entry fun mint_with_ref(
        ref_address: address,
        store: &mut ObjectTable<address, TokenData>,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) != ref_address, EInvalidReferal);

        mint(store, ctx);
        
        if (object_table::contains(store, ref_address)) {
            update_points(store, ref_address)
        };
    }

    public entry fun mint(
        store: &mut ObjectTable<address, TokenData>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(object_table::contains(store, sender) == false, ENotUniqueAddress);

        let nft = create_token(ctx);
        
        emit(MintTokenEvent {
            object_id: object::id(&nft),
            minter: sender,
            name: nft.name,
        });

        let data = TokenData {
            id: object::new(ctx),
            token_id: object::id(&nft),
            counter: object_table::length(store),
            current_points_xp: 0,
            owner: sender,
        };

        transfer::transfer(nft, sender);
        object_table::add(store, sender, data)
    }

    fun update_points(store: &mut ObjectTable<address, TokenData>, owner: address) {
        let record = object_table::borrow_mut<address, TokenData>(store, owner);
        record.current_points_xp = record.current_points_xp + 5;
    }

    fun create_token(ctx: &mut TxContext): Token {
        Token {
            id: object::new(ctx),
            name: string::utf8(NAME),
            description: string::utf8(DESCRIPTION),
            url: string::utf8(URL),
        }
    }
}