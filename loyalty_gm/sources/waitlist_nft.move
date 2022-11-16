module loyalty_gm::waitlist_nft {
    use sui::object::{Self, UID, ID};
    use std::string::{Self, String};
    use sui::object_table::{Self, ObjectTable};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event::{emit};
    use sui::dynamic_object_field as dof;

    // CONST 
    const NAME: vector<u8> = b"LoyaltyGM";
    const DESCRIPTION: vector<u8> = b"SBT for Loyalty Rewards Platform on Sui Blockchain";
    const URL: vector<u8> = b"ipfs://QmbtwaZubBFDXTvZ3S3ytdByaU85AzaY3yE8epVuhNkRZh";
    const CURRENT_POINTS: u128 = 0;
    const ALREADY_MINTED: u128 = 0;

    // ERROR 
    const ENotUniqueAddress: u64 = 0;

    /// Loyalty NFT.
    struct WaitlistToken has key {
        id: UID,
        name: String,
        description: String,
        url: String,
        
    }

    struct WaitlistStore has key {
        id: UID,
        counter: u128,
    }

    struct WaitlistRecord has key, store {
        id: UID,
        token_id: ID,
        owner: address,
        // current points
        currentPointsXP: u128,
        // number of nfts
        countOfMinted: u128,
    }

    // EVENT MINT
    struct MintTokenEVENT has copy, drop {
        object_id: ID,
        minter: address,
        name: string::String,
        // currentPointsXP: u128,
    }

    fun init(ctx: &mut TxContext){
        transfer::share_object(WaitlistStore {id: object::new(ctx), counter: 1});
        let nft = WaitlistToken {
            id: object::new(ctx),
            name: string::utf8(b"GENESIS TOKEN"),
            description: string::utf8(b"GENESIS TOKEN"),
            //owner: tx_context::sender(ctx),
            url: string::utf8(URL),
            // currentPointsXP: CURRENT_POINTS,
            // countOfMinted: 0,
        };
        transfer::share_object(nft);
    }

    public entry fun mint(
        ref_token: & WaitlistToken,
        store: &mut WaitlistStore,
        ctx: &mut TxContext
    ) {
        assert!(ref_token.owner != tx_context::sender(ctx), ENotUniqueAddress);
        update_counter(store);
        
        let nft = WaitlistToken {
            id: object::new(ctx),
            name: string::utf8(NAME),
            description: string::utf8(DESCRIPTION),
            //owner: tx_context::sender(ctx),
            url: string::utf8(URL),
            // currentPointsXP: CURRENT_POINTS,
            // countOfMinted: store.counter,
        };
        let sender = tx_context::sender(ctx);
        let nft_object = object::uid_to_inner(&nft.id);
        emit(MintTokenEVENT {
            object_id: nft_object,
            minter: sender,
            name: nft.name,
            // currentPointsXP: nft.currentPointsXP,
        });

        transfer::transfer(nft, sender);
        if(check_record(object::uid_to_inner(&ref_token.id), store)) {
            update_points(store, nft_object)
        };
        let record = WaitlistRecord {
            id: object::new(ctx),
            token_id: nft_object,
            countOfMinted: store.counter,
            currentPointsXP: 0,
            owner: sender,
        };

        dof::add(&mut store.id, sender, record);
    }

    fun update_counter(counter: &mut WaitlistStore){
        counter.counter = counter.counter + 1
    }

    fun update_points(store: &mut WaitlistStore, nft_object: ID) {
        let record = dof::borrow_mut<ID, WaitlistRecord>(&mut store.id, nft_object);
        record.currentPointsXP = record.currentPointsXP + 5;
    }

    fun check_record(address_id: ID, store: &mut WaitlistStore): bool {
        dof::exists_(&store.id, address_id)  
    }


}