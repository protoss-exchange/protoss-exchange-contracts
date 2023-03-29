from nile.common import ETH_TOKEN_ADDRESS
from nile.utils import to_uint, hex_address

async def run(nre):
  accounts = await nre.get_accounts(predeployed=True)
  account = accounts[0]

  # define the recipient address
  recipient = "0x05a0ca51cbc03e5ec8d9fad116f8737a6afe2613b3128ebd515643a1a5e5c52d"

  # define the amount to transfer
  amount = 2 * 10 ** 18

  print(
    f"Transferring {amount} WEI\n"
    f"from {hex_address(account.address)}\n"
    f"to   {recipient}\n"
  )

  # If we don't pass a max_fee, nile will estimate the transaction fee by default
  tx = await account.send(ETH_TOKEN_ADDRESS, "transfer", [recipient, *to_uint(amount)])

  tx_status, *_ = await tx.execute(watch_mode="track")

  print(tx_status.status, tx_status.error_message or "")
