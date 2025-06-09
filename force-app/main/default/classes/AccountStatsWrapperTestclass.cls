@isTest
public class AccountStatsWrapperTestclass {
    @isTest
    static void testWrapperInitialization() {
        // Create a test Account (no need to insert if not required)
        Account acc = new Account(Name = 'Test Account');
        
        // Instantiate the wrapper
        AccountStatsWrapper wrapper = new AccountStatsWrapper(acc);
        
        // Verify the Account property is assigned correctly
        System.assertEquals(acc, wrapper.account, 'Account property should match the passed Account');
        
        // Verify nonConvertedLeads is initialized to 0
        System.assertEquals(0, wrapper.nonConvertedLeads, 'nonConvertedLeads should initialize to 0');
    }
}