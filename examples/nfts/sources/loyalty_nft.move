module nfts::loyalty_nft {
    use sui::object::{Self, UID};
    use std::string::{Self, String};
    use sui::url::{Self, Url};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};


    // Mint Level
    const BASIC_LEVEL: u8 = 0;
    const CURRENT_POINTS: u128 = 0;
    const ELevel: u64 = 0;

    // Belongs to the creator
    struct LoyaltyManagerCap has key, store { id: UID }

    /// Loyalty NFT.
    struct LoyaltySystemNFT has key, store {
        id: UID,
         // name description
        name: String,
        // image url
        url: Url,
        // // supply of all collection
        // supply: u64,
        // level of nft [1-100]
        level: u8,
        // expiration timestamp (UNIX time) - app specific
        currentPointsXP: u128,
        // array of lvl points 
        // TODO:change to array
        // pointsToNextLvl: u128,
    }

    fun init(ctx: &mut TxContext){
        transfer::transfer(LoyaltyManagerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    /// Create a new devnet_nft
    public entry fun mint(
        name: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let nft = LoyaltySystemNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            url: url::new_unsafe_from_bytes(url),
            level: BASIC_LEVEL,
            currentPointsXP: CURRENT_POINTS,
        };
        let sender = tx_context::sender(ctx);
        
        transfer::transfer(nft, sender);
    }

    public entry fun update_lvl(nft: &mut LoyaltySystemNFT, new_lvl: u8, _: &mut TxContext) {
        assert!(nft.level + 1 == new_lvl, ELevel);
        nft.level = new_lvl
    }

    public fun currentLvl(nft: &mut LoyaltySystemNFT): &u8 {
        &nft.level
    }


}

#[test_only]
module sui::loyalty_nftTest {
    // use sui::devnet_nft::{Self, DevNetNFT};
    use sui::test_scenario as ts;
    use sui::transfer;
    use std::debug::{print};
    use nfts::loyalty_nft::{Self, LoyaltySystemNFT};

    #[test]
    fun mint_transfer_update() {
        let addr1 = @0xA;
        let addr2 = @0xB;

        let newLvl: u8 = 1; 
        // create the NFT
        let scenario = ts::begin(addr1);
        {
            loyalty_nft::mint(b"test", b"https://www.sui.io", ts::ctx(&mut scenario))
        };
        // send it from A to B
        ts::next_tx(&mut scenario, addr1);
        {
            let nft = ts::take_from_sender<LoyaltySystemNFT>(&mut scenario);
            transfer::transfer(nft, addr2);
        };
        // update its description
        ts::next_tx(&mut scenario, addr2);
        {
            let nft = ts::take_from_sender<LoyaltySystemNFT>(&mut scenario);
            print(loyalty_nft::currentLvl(&mut nft));
            loyalty_nft::update_lvl(&mut nft, newLvl, ts::ctx(&mut scenario));
            print(loyalty_nft::currentLvl(&mut nft));
            assert!(loyalty_nft::currentLvl(&mut nft) == &newLvl, 0);
            ts::return_to_sender(&mut scenario, nft);
        };
        ts::end(scenario);
    }
}
