// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

// Contrato derivado de ERC1155 para permitir instanciação
contract MyERC1155 is ERC1155 {
    constructor(string memory uri) ERC1155(uri) {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public {
        _mint(to, id, amount, data);
    }
}

contract ERC1155Test is Test {
    MyERC1155 public token;

    function setUp() public {
        token = new MyERC1155("https://token-cdn-domain/{id}.json");
    }

    // Função 1.

    function testSetOfSafeTransferFromValid() public {
        for (uint160 owner_id = 1; owner_id <= 3; owner_id++) {
            for (uint160 recipient_id = 1; recipient_id <= 3; recipient_id++) {
                for (uint256 id = 1; id <= 5; id++) {
                    for (uint256 value = 1; value <= 10; value++) { // value > 0
                        address owner = address(owner_id);
                        address recipient = address(recipient_id);

                        token.setApprovalForAll(owner, true);
                        token.setApprovalForAll(recipient, true);

                        if (owner != recipient) {
                            vm.startPrank(owner);
                            token.mint(owner, id, value, "");

                            uint256 older_owner_money = token.balanceOf(owner, id);
                            uint256 older_recipient_money = token.balanceOf(recipient, id);

                            token.safeTransferFrom(owner, recipient, id, value, "");

                            assertEq(token.balanceOf(owner, id), older_owner_money - value);
                            assertEq(token.balanceOf(recipient, id), older_recipient_money + value);

                            vm.stopPrank(); 
                        }
                    }
                }
            }
        }
    }

    function testSafeTransferFromInvalidMissingApprovalForAll() public {
        address same_address = address(0x01);
        vm.expectRevert();
        token.safeTransferFrom(same_address, same_address, 1, 100, "");
    }

    function testSafeTransferFromInvalidSender() public {
        address owner = address(0);
        address recipient = address(0x1);
        vm.expectRevert();
        token.safeTransferFrom(owner, recipient, 1, 10, "");
    }

    function testSafeTransferFromInvalidReceiver() public {
        address owner = address(0x1);
        address recipient = address(0);
        vm.expectRevert();
        token.safeTransferFrom(owner, recipient, 1, 10, "");
    }

    function testTransferInvalidInsufficientBalance() public {
        address owner = address(0x1);
        address recipient = address(0x2);

        token.mint(owner, 1, 10, "");        

        vm.prank(owner);
        vm.expectRevert();
        token.safeTransferFrom(owner, recipient, 1, 100000, "");
    }
    
    function testTranferFromInvalidRevokeApprovalAndTransfer() public {
        address owner = address(0x1);
        address recipient = address(0x2);

        vm.prank(owner);
        token.setApprovalForAll(recipient, true);
        
        vm.prank(owner);
        token.setApprovalForAll(recipient, false);

        vm.prank(recipient);
        vm.expectRevert();
        token.safeTransferFrom(owner, recipient, 1, 10, "");
    }

    // Função 2.

    function testBatchTransferValid() public {
        uint256[] memory ids = new uint256[](4);  
        uint256[] memory values = new uint256[](4);  

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 4;
        ids[3] = 5;

        values[0] = 1;
        values[1] = 1;
        values[2] = 1;
        values[3] = 1;

        address owner = address(0x1);
        address recipient = address(0x2);

        token.mint(owner, 1, 1000, ""); 
        token.mint(owner, 2, 1000, "");     
        token.mint(owner, 4, 1000, "");            
        token.mint(owner, 5, 1000, "");     

        token.setApprovalForAll(owner, true);
        token.setApprovalForAll(recipient, true);

        vm.prank(owner);
        token.safeBatchTransferFrom(owner, recipient, ids, values, "");
    }

    function testBatchTransferInvalidArrayLength() public {
        uint256[] memory ids = new uint256[](4);  
        uint256[] memory values = new uint256[](4);  

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 4;
        ids[3] = 5;

        values[0] = 1;
        values[1] = 1;
        values[2] = 1;

        address owner = address(0x1);
        address recipient = address(0x2);

        token.mint(owner, 1, 1000, "");        

        token.setApprovalForAll(owner, true);
        token.setApprovalForAll(recipient, true);

        vm.prank(owner);
        vm.expectRevert();
        token.safeBatchTransferFrom(owner, recipient, ids, values, "");
    }

    function testSafeBatchTransferFromInvalidMissingApprovalForAll() public {
        uint256[] memory ids = new uint256[](4); 
        uint256[] memory values = new uint256[](3);  

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 4;
        ids[3] = 5;

        values[0] = 10;
        values[1] = 100;
        values[2] = 1000;

        address same_address = address(0x01);
        vm.expectRevert();
        token.safeBatchTransferFrom(same_address, same_address, ids, values, "");
    }

    function testSafeBatchTransferFromInvalidSender() public {
        uint256[] memory ids = new uint256[](4);  
        uint256[] memory values = new uint256[](3);  

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 4;
        ids[3] = 5;

        values[0] = 10;
        values[1] = 100;
        values[2] = 1000;

        address owner = address(0);
        address recipient = address(0x1);

        vm.expectRevert();
        token.safeBatchTransferFrom(owner, recipient, ids, values, "");
    }

    function testSafeBatchTransferFromInvalidReceiver() public {
        uint256[] memory ids = new uint256[](4);  
        uint256[] memory values = new uint256[](3);  

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 4;
        ids[3] = 5;

        values[0] = 10;
        values[1] = 100;
        values[2] = 1000;

        address owner = address(0x1);
        address recipient = address(0);

        vm.expectRevert();
        token.safeBatchTransferFrom(owner, recipient, ids, values, "");
    }

    function testBatchTransferInvalidInsufficientBalance() public {
        uint256[] memory ids = new uint256[](4);  
        uint256[] memory values = new uint256[](3);  

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 4;
        ids[3] = 5;

        values[0] = 1000;
        values[1] = 10000;
        values[2] = 1000000;

        address owner = address(0x1);
        address recipient = address(0x2);

        token.mint(owner, 1, 10, "");        

        vm.prank(owner);
        vm.expectRevert();
        token.safeBatchTransferFrom(owner, recipient, ids, values, "");
    }

    function testBatchTranferFromInvalidRevokeApprovalAndTransfer() public {
        uint256[] memory ids = new uint256[](4);  
        uint256[] memory values = new uint256[](3);  

        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 4;
        ids[3] = 5;

        values[0] = 10;
        values[1] = 100;
        values[2] = 1000;

        address owner = address(0x1);
        address recipient = address(0x2);

        vm.prank(owner);
        token.setApprovalForAll(recipient, true);
        
        vm.prank(owner);
        token.setApprovalForAll(recipient, false);

        vm.prank(recipient);
        vm.expectRevert();
        token.safeBatchTransferFrom(owner, recipient, ids, values, "");
    }

}