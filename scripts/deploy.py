from time import time
from brownie import network, accounts, config, Lottery

from scripts.helpful_scripts import fund_with_link, getAccount, getContract
from web3 import Web3


def deploy_Lottery():
    account = getAccount()
    lottery = Lottery.deploy(
        getContract("eth_usd_price_feed"),
        getContract("vrf_coordinator"),
        getContract("link_token"),
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["key_harsh"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    return lottery


def startLottery():
    account = getAccount()
    lottery = Lottery[-1]
    tx = lottery.startLottery({"from": account})
    tx.wait(1)
    print("Lottery started")


def enter_Lottery():
    account = getAccount()
    lottery = Lottery[-1]
    tx = lottery.enter({"from": account, "value": Web3.toWei(60, "ether")})
    tx.wait(1)
    print("enter lottery")


def end_Lottery():
    account = getAccount()
    lottery = Lottery[-1]
    ty = fund_with_link(lottery.address)
    ty.wait(1)
    tx = lottery.endLottery({"from": account})
    tx.wait(1)
    # time.sleep(180)
    print("end lottery", lottery.recentWinner())


def main():
    deploy_Lottery()
    startLottery()
    enter_Lottery()
    end_Lottery()
