async def run(nre):
    accounts = await nre.get_accounts(predeployed=True)
    print("First Account:", accounts)