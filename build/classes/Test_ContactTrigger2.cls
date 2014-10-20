@isTest
private class Test_ContactTrigger2 {

    //
    // Verify that a contact with can not be added to a account 
    // that already has a contact with the same personnummer__c  
    //
    private static testMethod void checkPersonnummerOnContact_1() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(10);
        insert accs;
        
        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(10, accs);
        conts.get(0).Personnummer__c = '730911-2312';//Nisse
        conts.get(0).AccountID = accs.get(0).id;
        conts.get(1).Personnummer__c = '730915-2512';//Bosse
        conts.get(1).AccountID = accs.get(1).id;
        insert conts;
        
        Test.startTest();
            try {
                // Try to insert Bosse to the same account again
                List<Contact> conts2 = TestFactory.buildTestContacts(1, accs);
                conts2.get(0).Personnummer__c = '730915-2512';
                conts.get(0).AccountID = accs.get(1).id;
                insert conts2;
            }
            catch(Exception e) {
                Boolean expectedExceptionThrown =  e.getMessage().contains('Kontakten med detta personnummer finns redan för den här kunden.') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            } 
        Test.stopTest();
    }

    //
    // Verify that a contact with can be added to a account 
    // that don't has a contact with the same personnummer__c  
    //
    private static testMethod void checkPersonnummerOnContact_2() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(10);
        insert accs;
        
        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(10, accs);
        conts.get(0).Personnummer__c = '730911-2312';//Nisse
        conts.get(0).AccountID = accs.get(0).id;
        conts.get(1).Personnummer__c = '730915-2512';//Bosse
        conts.get(1).AccountID = accs.get(1).id;
        insert conts;
        
        Test.startTest();
            try {
                // Insert Bosse to another account
                List<Contact> conts2 = TestFactory.buildTestContacts(1, accs);
                conts2.get(0).Personnummer__c = '730915-2512';
                conts.get(0).AccountID = accs.get(0).id;
                insert conts2;
            }
            catch(Exception e) {
                Boolean expectedExceptionThrown =  e.getMessage().contains('Kontakten med detta personnummer finns redan för den här kunden.') ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            } 
        Test.stopTest();
    }

    //
    // Verify that parent account id is set on the contact
    //
    private static testMethod void setParentAccountOnContact_1() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(10);
        insert accs;

        // Set one account as parent account
        for(Account a : accs) {
            a.ParentId = a.id <> accs.get(0).id ? accs.get(0).Id : null;
        }
        update accs;

        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(10, accs);
        
        Test.startTest();
            insert conts;
        Test.stopTest();

        // Get all accounts with ids from contacts
        Map<ID,Account> accs_res_map = new Map<ID,Account>();

        for(Account a : accs) {
            accs_res_map.put(a.ParentId, a);
        }

        for(Contact c : conts) {
            if(accs_res_map.containsKey(c.AccountId)) {
                System.assertEquals(c.AccountId, accs_res_map.get(c.AccountId).ParentId);
            }
        }
    }

    //
    // Verify that parent account id is NOT set on the contact
    //
    private static testMethod void setParentAccountOnContact_2() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(10);
        insert accs;

        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(10, accs);
        
        Test.startTest();
            insert conts;
        Test.stopTest();

        // Get all accounts with ids from contacts
        Map<ID,Account> accs_res_map = new Map<ID,Account>();

        for(Account a : accs) {
            accs_res_map.put(a.ParentId, a);
        }

        for(Contact c : conts) {
            System.assertEquals(accs_res_map.containsKey(c.AccountId), false);
        }
    }

    //
    // Verify that parent account id is set on the contact in BULK
    //
    private static testMethod void setParentAccountOnContact_bulk() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(200);
        insert accs;

        // Set one account as parent account
        for(Account a : accs) {
            a.ParentId = a.id <> accs.get(0).id ? accs.get(0).Id : null;
        }
        update accs;

        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(200, accs);
        
        Test.startTest();
            insert conts;
        Test.stopTest();

        // Get all accounts with ids from contacts
        Map<ID,Account> accs_res_map = new Map<ID,Account>();

        for(Account a : accs) {
            accs_res_map.put(a.ParentId, a);
        }

        for(Contact c : conts) {
            if(accs_res_map.containsKey(c.AccountId)) {
                System.assertEquals(c.AccountId, accs_res_map.get(c.AccountId).ParentId);
            }
        }
    } 
}