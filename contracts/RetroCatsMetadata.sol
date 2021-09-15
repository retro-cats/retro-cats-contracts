// SPDX-License-Identifier: MIT
/** 
██████╗ ███████╗████████╗██████╗  ██████╗      ██████╗ █████╗ ████████╗███████╗    
██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    
██████╔╝█████╗     ██║   ██████╔╝██║   ██║    ██║     ███████║   ██║   ███████╗    
██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║    ██║     ██╔══██║   ██║   ╚════██║    
██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝    ╚██████╗██║  ██║   ██║   ███████║    
╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    
                                                                                   
███╗   ███╗███████╗████████╗ █████╗ ██████╗  █████╗ ████████╗ █████╗               
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗              
██╔████╔██║█████╗     ██║   ███████║██║  ██║███████║   ██║   ███████║              
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║  ██║██╔══██║   ██║   ██╔══██║              
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║██████╔╝██║  ██║   ██║   ██║  ██║              
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝              
                                                                          
<<https://github.com/retro-cats/retro-cats-contracts>>

*/
pragma solidity 0.8.3;
/*
* @title Our contract for describing what a cat looks like.
* @dev This contract has almost 0 functionality, except for rngToCat
* which is used to "say" what the random number (the DNA) 
* of a cat would result in for a cat
*/
contract RetroCatsMetadata {
    uint256 internal s_maxChanceValue = 10000;
    struct RetroCat {
        Background background;
        Frame frame;
        Breed breed;
        Eyes eyes;
        Hair hair;
        Bling bling;
        Head head;
        Item item;
        Ring ring;
        Earring earring;
        Vice vice; 
    }
    /**
    * @dev Percentages for each trait
    * @dev each row will always end with 10000
    * When picking a trait based on RNG, we will get a value between 0 - 99999
    * We choose the trait based on the sum of the integers up to the index
    * For example, if my random number is 251, and my array is [250, 200, 10000]
    *      This means my trait is at the 1st index. 251 is higher than 250, but lower than
    *      250 + 200
    */

    uint256 internal s_totalTraits = 11;
    enum Background{Black, Blue, Green, Grey, Orange, Pink, Purple, Red, Yellow, LightBlue, LightGreen, LightPink, LightYellow, D1B, D1O, D1P, D1Y, D2B, D2O, D2P, D2Y, D3B, D3O, D3P, D3Y, D4B, D4O, D4P, D4Y, D5B, D5O, D5P, D5Y}
    uint256[] internal S_BACKGROUND_METADATA = [500, 1100, 600, 1000, 900, 1400, 700, 2000, 800, 400, 270, 30, 100, 1, 6, 11, 16, 2, 7, 12, 17, 3, 8, 13, 18, 4, 9, 14, 19, 5, 10, 15, 10, s_maxChanceValue];
    enum Frame{Black, Brass, Browne, Glit, Gold, Leather, Pine, Silver, White, Wood, None}
    uint256[] internal S_FRAME_METADATA = [250, 150, 300, 200, 40, 10, 80, 70, 400, 100, 8400, s_maxChanceValue];
    enum Breed{Bengal, Calico, Chimera, HighColor, Mitted, Solid, Tabby, Tortie, Tuxedo, Van, Cloud, Lightning, Mister, Spotty, Tiger}
    uint256[] internal S_BREED_METADATA = [90, 600, 75, 400, 900, 2700, 2100, 155, 2600, 280, 35, 1, 5, 50, 9, s_maxChanceValue];
    enum Eyes{BlueOpen, BlueWink, Closed, GreenOpen, GreenWink, OrangeOpen, OrangeWink, YellowOpen, YellowWink}
    uint256[] internal S_EYES_METADATA = [1200, 10, 2000, 1400, 90, 1800, 1000, 1600, 900, s_maxChanceValue];    
    enum Hair{ Braid, Dreads, Fro, LongFlipped, LongStraight, Mullet, Muttonchops, Pageboy, ShortFlipped, None, BrownShag, GingerBangs, GingerShag, LongRocker, Pigtails, PunkSpikes, StackedPerm, TinyBraids, TVMom, Wedge }
    uint256[] internal S_HAIR_METADATA = [600, 4, 1000, 1200, 1200, 1, 500, 300, 700, 1600, 400, 450, 5, 7, 80, 3, 650, 350, 750, 200, s_maxChanceValue];
    enum Bling{BlueNeckscarf, CopperBracelet, DiscoChest, HandlebarMustache, LongMustache, LoveBeads, MoonNecklaces, PeaceNecklace, PearlNecklace, PukaShellNecklace, CollarCuffs, FeatherBoa, CameoChoker, Woodenbeads, GoldFringe, TurquoiseNecklace, OrangeBoa, CoralNecklace, SilverFringe, SilverMoon, SunnyBeads}
    uint256[] internal S_BLING_METADATA = [1100, 200, 800, 500, 200, 700, 1400, 400, 800, 600, 1200, 40, 2, 350, 250, 450, 5, 50, 300, 650, 3, s_maxChanceValue];
    enum Head{AviatorGlasses, Daisy, Eyepatch, Headband, Headscarf, HeartGlasses, NewsboyCap, RoundGlasses, SquareGlasses, TopHat, BraidedHeadband, DaisyHeadband, DiscoHat, GoldTBand, GrandmaGlasses, GrandpaGlasses, GreenGlasses, RainbowScarf, RedBeret, TinselWig}
    uint256[] internal S_HEAD_METADATA = [1200, 1100, 1, 1300, 600, 300, 1000, 400, 350, 900, 250, 60, 4, 300, 550, 500, 30, 950, 200, 5, s_maxChanceValue];
    enum Item{Atari, Disco, Ether, FlooyDisc, Houseplants, LandscapePainting, LavaLamp, PalmSurboard, Record, RedGuitar, TennisRacket, NerfFootball, Skateboard, Personalcomputer, Afghan, Fondue, LawnDarts, Rollerskates, Phone, Bicycle, Chair}
    uint256[] internal S_ITEM_METADATA = [90, 800, 1, 1400, 1200, 900, 700, 550, 1300, 1000, 6, 400, 600, 200, 50, 60, 150, 250, 40, 300, 3, s_maxChanceValue];
    enum Ring{Emerald, MoodBlue, MoodGreen, MoodPurple, MoodRed, Onyx, Ruby, Sapphire, Tortoiseshell, Turquoise, ChainRings, StackRings, NoseRing, MensGoldRing, MoonRing, EtherRing, OrbRing, GiantDiamond, TattooCat, TattooFish, TattooBird}
    uint256[] internal S_RING_METADATA = [400, 1000, 900, 600, 850, 1300, 1200, 800, 500, 700, 250, 200, 150, 200, 500, 60, 350, 30, 1, 6, 3, s_maxChanceValue];
    enum Earring{Coral, DiamondStuds, GoldBobs, GoldChandelier, GoldHoops, OrangeWhite, RubyStuds, SilverHoops, Tortoiseshell, Turquoise, None, BlueWhite, GreenWhite, SilverChandelier, SapphireStuds, EmeraldStuds, PearlBobs, GoldChains, SilverChains, PinkMod, GoldJellyfish}
    uint256[] internal S_EARRING_METADATA = [400, 1, 200, 90, 1200, 500, 200, 1000, 300, 600, 3000, 250, 450, 105, 7, 5, 375, 725, 575, 4, 13, s_maxChanceValue];
    enum Vice{Beer, Bong, Cigarette, Eggplant, JelloSalad, Joint, Mushrooms, PetRock, PurpleBagOfCoke, Whiskey, CheeseBall, ProtestSigns, TequilaSunrise, Grasshopper, PinaColada, QueensofDestructionCar, SPF4, SWPlush, SlideProjector, Tupperware, TigerMagazine}
    uint256[] internal S_VICE_METADATA = [1000, 420, 1100, 1300, 50, 1200, 1450, 7, 30, 500, 400, 550, 200, 650, 460, 1, 20, 54, 2, 600, 6, s_maxChanceValue];

    uint256[][] public S_TRAIT_ARRAYS = [S_BACKGROUND_METADATA, S_FRAME_METADATA, S_BREED_METADATA, S_EYES_METADATA, S_HAIR_METADATA, S_BLING_METADATA, S_HEAD_METADATA, S_ITEM_METADATA, S_RING_METADATA, S_EARRING_METADATA, S_VICE_METADATA];

    string public purr = "Meow!";

    function rngToCat(uint256 randomNumber) public view returns (RetroCat memory retroCat){
    // function rngToCat(uint256 randomNumber) public view returns (uint256){
        uint256[][] memory traitArrays = S_TRAIT_ARRAYS;
        uint256[] memory traitIndexes = new uint256[](s_totalTraits);
        for (uint i = 0; i < s_totalTraits; i++){
            uint256 traitIndex = getTraitIndex(traitArrays[i], getModdedRNG(randomNumber, i));
            traitIndexes[i] = traitIndex;
        }
        
        // retroCat = RetroCat(Background(traitIndexes[0]),Frame(1),Breed(1),Eyes(1),Hair(1),Bling(1),Head(1),Item(1),Ring(1),Earring(1),Vice(1));
        retroCat = RetroCat({
            background: Background(traitIndexes[0]),
            frame: Frame(traitIndexes[1]),
            breed: Breed(traitIndexes[2]),
            eyes: Eyes(traitIndexes[3]),
            hair: Hair(traitIndexes[4]),
            bling: Bling(traitIndexes[5]),
            head: Head(traitIndexes[6]),
            item: Item(traitIndexes[7]),
            ring: Ring(traitIndexes[8]),
            earring: Earring(traitIndexes[9]),
            vice: Vice(traitIndexes[10])
        });
    }

    function getModdedRNG(uint256 randomNumber, uint256 seed) public view returns(uint256 modded_rng){
        uint256 newRng = uint256(keccak256(abi.encode(randomNumber, seed)));
        modded_rng = newRng % s_maxChanceValue;
    }

    function getTraitIndex(uint256[] memory traitArray, uint256 moddedRNG) public pure returns(uint256){
        uint256 cumulativeSum = 0;
        for(uint i =0; i<traitArray.length; i++){
            if(moddedRNG >= cumulativeSum && moddedRNG < cumulativeSum + traitArray[i]){
                return i;
            }
            cumulativeSum = cumulativeSum + traitArray[i];
        }
        revert("Got a value outside of the s_maxChanceValue");
    }

    //  function uint2str(
    //     uint256 _i
    //     )
    //     internal
    //     pure
    //     returns (string memory str)
    //     {
    //     if (_i == 0)
    //     {
    //         return "0";
    //     }
    //     uint256 j = _i;
    //     uint256 length;
    //     while (j != 0)
    //     {
    //         length++;
    //         j /= 10;
    //     }
    //     bytes memory bstr = new bytes(length);
    //     uint256 k = length;
    //     j = _i;
    //     while (j != 0)
    //     {
    //         bstr[--k] = bytes1(uint8(48 + j % 10));
    //         j /= 10;
    //     }
    //     str = string(bstr);
    // }
}
