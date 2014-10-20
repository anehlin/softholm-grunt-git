@isTest
private class Test_CaseTrigger2 {

    //
    // Verify that opportunities with opportunityline items has been created
    // if case status is set to 'Stängt'
    //
    private static testMethod void updateOpportunityLineItemTest() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(1);
        insert accs;

        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(2, accs);
        insert conts;

        //Create mock products
        String[] productNames = new String[]{ ' Ny användare    ',
                                             '  Autoimport av försäljningssiffror   ',
                                             '  Extra rapportgenerator  ',
                                             '  Extra lönekörning   ',
                                             '  Utbildning/h    ',
                                             '  Webbschema  ' };

        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < productNames.size(); i++) {
            Product2 prod = new Product2(
                    Name = productNames[i],
                    Description = productNames[i],
                    ProductCode = 'KK_' + String.valueOf(i),
                    Charging_Period__c = math.mod(i,2)==0 ? '/month' : '/piece',
                    IsActive = true);
            products.add(prod);
        }
        insert products;

        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();

        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        List<PricebookEntry> pbe_list = new List<PricebookEntry>();
        for(Integer i = 0; i < products.size(); i++) {
            PricebookEntry standardPrice = new PricebookEntry(
                                    Pricebook2Id = pricebookId,
                                    UnitPrice = 10.0 + Decimal.valueOf(i),
                                    Product2Id = products.get(i).Id,
                                    IsActive = true,
                                    UseStandardPrice = false);
           pbe_list.add(standardPrice);
        }
        insert pbe_list;

        Test.startTest();
        // Create mock cases
        List<Case> cases = TestFactory.buildTestCases(2, accs, conts);
        for(Integer i = 0; i < cases.size(); i++) {
            cases.get(i).Status = 'Nytt';
            cases.get(i).Typ_av_case__c = 'TypAvCase';
        }
        insert cases;

        Map<ID,Case> case_map_1 = new Map<ID,Case>(cases);
        List<Case> case_list_1 = [Select Status, Subject From Case
                                Where Id in: case_map_1.keyset()];

        for(Case c : case_list_1)  {
            System.assertEquals('Nytt', c.Status);
            System.assertEquals('TypAvCase', c.Subject);
        }

       List<CaseProductObject__c> cpo_list = new List<CaseProductObject__c>();

        for(Integer i = 0; i < cases.size(); i++) {
            CaseProductObject__c cpo = new CaseProductObject__c();
            cpo.Name = 'Test_' + i;
            cpo.Antal__c = i;
            cpo.Enhetspris__c = 10 + Decimal.valueOf(i);
            cpo.Enhet__c = math.mod(i,2)==0 ? '/piece' : '/month';
            cpo.PriceBookEntry__c =  pbe_list.get(0).id;
            cpo.Case__c = cases.get(i).id;
            cpo.Product__c = i < products.size() ? products.get(i).id : products.get(0).id;
            cpo_list.add(cpo);
        }
        insert cpo_list;

        Map<ID,Case> case_map_2 = new Map<ID,Case>(cases);
        List<CaseProductObject__c> cpo_list_1 = [Select Case__c From CaseProductObject__c
                                                 Where Case__c in: case_map_2.keyset()];

        System.assertEquals(cases.size(),cpo_list_1.size());

        for(Integer i = 0; i < cases.size(); i++) {
            cases.get(i).Status = 'Stängt';
        }
        update cases;

        Map<ID,Case> case_map_3 = new Map<ID,Case>(cases);

        List<Case> case_list_3 = [Select Status, hasOpportunity__c From Case
                                Where Id in: case_map_3.keyset()];

        for(Case c : case_list_3)  {
            System.assertEquals('Stängt', c.Status);
            System.assertEquals(true, c.hasOpportunity__c);
        }

        List<Opportunity> opps = [Select Name, AccountID From Opportunity
                                  Where Case__c in: case_map_3.keyset()];

        System.assertEquals(cases.size(), opps.size());

        Map<ID,Opportunity> opps_map = new Map<ID,Opportunity>(opps);

        List<OpportunityLineItem> oli_list = [Select id, Quantity, PricebookEntry.Product2Id, PricebookEntryId, UnitPrice
                                            From OpportunityLineItem
                                            Where OpportunityId in: opps_map.keyset()];

        System.assertEquals(cpo_list.size(),oli_list.size());
        
        Test.stopTest();

    }

    //
    // Verify that no opportunities with opportunityline items has been created
    // if case status is set other status than 'Stängt'
    //
    private static testMethod void updateOpportunityLineItemTest_Negative() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(1);
        insert accs;

        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(2, accs);
        insert conts;

        //Create mock products
        String[] productNames = new String[]{ ' Ny användare    ',
                                             '  Autoimport av försäljningssiffror   ',
                                             '  Extra rapportgenerator  ',
                                             '  Extra lönekörning   ',
                                             '  Utbildning/h    ',
                                             '  Webbschema  ' };

        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < productNames.size(); i++) {
            Product2 prod = new Product2(
                    Name = productNames[i],
                    Description = productNames[i],
                    ProductCode = 'KK_' + String.valueOf(i),
                    Charging_Period__c = math.mod(i,2)==0 ? '/month' : '/piece',
                    IsActive = true);
            products.add(prod);
        }
        insert products;

        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();

        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        List<PricebookEntry> pbe_list = new List<PricebookEntry>();
        for(Integer i = 0; i < products.size(); i++) {
            PricebookEntry standardPrice = new PricebookEntry(
                                    Pricebook2Id = pricebookId,
                                    UnitPrice = 10.0 + Decimal.valueOf(i),
                                    Product2Id = products.get(i).Id,
                                    IsActive = true,
                                    UseStandardPrice = false);
           pbe_list.add(standardPrice);
        }
        insert pbe_list;

        Test.startTest();
        // Create mock cases
        List<Case> cases = TestFactory.buildTestCases(2, accs, conts);
        for(Integer i = 0; i < cases.size(); i++) {
            cases.get(i).Status = 'Nytt';
            cases.get(i).Typ_av_case__c = 'TypAvCase';
        }
        insert cases;

        Map<ID,Case> case_map_1 = new Map<ID,Case>(cases);
        List<Case> case_list_1 = [Select Status, Subject From Case
                                Where Id in: case_map_1.keyset()];

        for(Case c : case_list_1)  {
            System.assertEquals('Nytt', c.Status);
            System.assertEquals('TypAvCase', c.Subject);
        }

       List<CaseProductObject__c> cpo_list = new List<CaseProductObject__c>();

        for(Integer i = 0; i < cases.size(); i++) {
            CaseProductObject__c cpo = new CaseProductObject__c();
            cpo.Name = 'Test_' + i;
            cpo.Antal__c = i;
            cpo.Enhetspris__c = 10 + Decimal.valueOf(i);
            cpo.Enhet__c = math.mod(i,2)==0 ? '/piece' : '/month';
            cpo.PriceBookEntry__c =  pbe_list.get(0).id;
            cpo.Case__c = cases.get(i).id;
            cpo.Product__c = i < products.size() ? products.get(i).id : products.get(0).id;
            cpo_list.add(cpo);
        }
        insert cpo_list;

        Map<ID,Case> case_map_2 = new Map<ID,Case>(cases);
        List<CaseProductObject__c> cpo_list_1 = [Select Case__c From CaseProductObject__c
                                                 Where Case__c in: case_map_2.keyset()];

        System.assertEquals(cases.size(),cpo_list_1.size());

        for(Integer i = 0; i < cases.size(); i++) {
            cases.get(i).Status = 'Pågående';
        }
        update cases;

        Map<ID,Case> case_map_3 = new Map<ID,Case>(cases);

        List<Case> case_list_3 = [Select Status, hasOpportunity__c From Case
                                Where Id in: case_map_3.keyset()];

        for(Case c : case_list_3)  {
            System.assertEquals('Pågående', c.Status);
            System.assertEquals(false, c.hasOpportunity__c);
        }

        List<Opportunity> opps = [Select Name, AccountID From Opportunity
                                  Where Case__c in: case_map_3.keyset()];

        System.assertEquals(0, opps.size());

        Map<ID,Opportunity> opps_map = new Map<ID,Opportunity>(opps);

        List<OpportunityLineItem> oli_list = [Select id, Quantity, PricebookEntry.Product2Id, PricebookEntryId, UnitPrice
                                            From OpportunityLineItem
                                            Where OpportunityId in: opps_map.keyset()];

        System.assertEquals(0,oli_list.size());
        
        Test.stopTest();

    }
}