module loyalty_gm::waitlist_nft {
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
    const CURRENT_POINTS: u128 = 0;
    const ALREADY_MINTED: u128 = 0;

    /// Loyalty NFT.
    struct WaitlistToken has key, store {
        id: UID,
        name: String,
        description: String,
        url: String,
        // current points
        currentPointsXP: u128,
        // number of nfts
        countOfMinted: u128,
    }

    struct Counter has key {
        id: UID,
        counter: u128,
    }

    

    // EVENT MINT
    struct MintTokenEVENT has copy, drop {
        object_id: ID,
        minter: address,
        name: string::String,
        currentPointsXP: u128,
    }

    fun init(ctx: &mut TxContext){
        transfer::share_object(Counter {id: object::new(ctx), counter: 0})

    }

    public entry fun mint(
        code: address,
        counter: &mut Counter,
        ctx: &mut TxContext
    ) {
        update_counter(counter);
        let nft = WaitlistToken {
            id: object::new(ctx),
            name: string::utf8(NAME),
            description: string::utf8(DESCRIPTION),
            url: string::utf8(URL),
            currentPointsXP: CURRENT_POINTS,
            countOfMinted: counter.counter,
        };
        let sender = tx_context::sender(ctx);
        
        emit(MintTokenEVENT {
            object_id: object::uid_to_inner(&nft.id),
            minter: sender,
            name: nft.name,
            currentPointsXP: nft.currentPointsXP,
        });

        transfer::transfer(nft, sender);
    }

    fun update_counter(counter: &mut Counter){
        counter.counter = counter.counter + 1
    }

    public fun current_points(nft: &mut WaitlistToken): &u128 {
        &nft.currentPointsXP
    }

}