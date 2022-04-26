from scripts.deploy import deploy_Lottery
from scripts.helpful_scripts import fund_with_link, getAccount, getContract
from web3 import Web3


def test_enter_lottery():
    lottery = deploy_Lottery()
    lottery.startLottery({"from": getAccount()})
    lottery.enter({"from": getAccount(index=1), "value": Web3.toWei(51, "ether")})
    lottery.enter({"from": getAccount(index=2), "value": Web3.toWei(55, "ether")})
    lottery.enter({"from": getAccount(index=3), "value": Web3.toWei(57, "ether")})
    lottery.enter({"from": getAccount(index=4), "value": Web3.toWei(59, "ether")})
    fund_with_link(lottery.address)
    tx = lottery.endLottery({"from": getAccount()})
    tx.wait(1)
    requestId = tx.events["RequestedRandomness"]["requestId"]
    RANDOM = 777
    getContract("vrf_coordinator").callBackWithRandomness(
        requestId, RANDOM, lottery.address, {"from": getAccount()}
    )
    # Assert
    assert lottery.recentWinner() == getAccount(index=2)
    assert lottery.balance() == 0
