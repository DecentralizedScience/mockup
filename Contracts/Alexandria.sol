
pragma solidity ^0.4.0;

contract Alexandria{
    //Variables
    mapping(uint => address) DAJsAdresses;
    uint numDAJs;

    address owner;

    //Events
    event DAJRegistered(address _DAJAdress);

    //Functions
    function Alexandria() public{
        owner = msg.sender;
        numDAJs = 0;
    }

    function registerDAJ(address DAJAdress) public{
        DAJsAdresses[numDAJs] = DAJAdress;
        numDAJs++;
        DAJRegistered(DAJAdress);
    }
}
