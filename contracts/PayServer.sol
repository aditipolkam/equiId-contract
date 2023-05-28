// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts@4.7.0/access/Ownable.sol";
import {Base64} from "./libraries/Base64.sol";

contract PayServer is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenIds;
    address public owner;

    constructor() ERC721("PayRangeNFTs", "PRN") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    struct User {
        string detailsCid;
        string payslipCid;
        uint256 tokenId;
    }

    mapping(address => User) public userMap;

    function setUserDetails(
        address _addr,
        string memory _claim,
        string memory _detailsCid,
        string memory _payslipCid
    ) public onlyOwner returns (uint256) {
        User storage user = userMap[_addr];
        mintClaimNFT(_addr, _claim, tokenIds.current());
        user.detailsCid = _detailsCid;
        user.payslipCid = _payslipCid;
        user.tokenId = tokenIds.current();
        return tokenIds.current();
    }

    string svgPartOne =
        "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='";
    string svgPartTwo =
        "'/><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    string[] colors = [
        "red",
        "#08C2A8",
        "black",
        "yellow",
        "blue",
        "green",
        "pink",
        "purple",
        "orange",
        "brown",
        "gray",
        "lavender",
        "aquamarine",
        "lime",
        "deeppink"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pickRandomColor(
        uint256 tokenId
    ) public view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked("EPIC_COLOR", Strings.toString(tokenId)))
        );
        rand = rand % colors.length;
        return colors[rand];
    }

    function mintClaimNFT(
        address _receiver,
        string memory _claim,
        uint256 newItemId
    ) internal {
        string memory randomColor = pickRandomColor(newItemId);
        string memory finalSvg = string(
            abi.encodePacked(
                svgPartOne,
                randomColor,
                svgPartTwo,
                _claim,
                "</text></svg>"
            )
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _claim,
                        '", "description": "A collection anonymous pay claims.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _safeMint(_receiver, newItemId);
        _setTokenURI(newItemId, finalTokenURI);

        tokenIds.increment();
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
