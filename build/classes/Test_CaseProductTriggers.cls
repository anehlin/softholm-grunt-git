@isTest(SeeAllData=true)
private class Test_CaseProductTriggers {

    //
    // Verify that the CaseProductObject__c is updated triggering
    // an update of Case
    //
    private static testMethod void updateAntal() {

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
                                             '  Kassakoppling   ',
                                             '  Nedladdningskod ',
                                             '  Reseersättning  ',
                                             '  Stämpelklocka   ',
                                             '  Utbildning eller systemombyggnad heldag ',
                                             '  Utbildning eller systemombyggnad per timme  ',
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

        // Get the standard price book
        List<Pricebook2> standardPB =[Select Id, Name
                                      From Pricebook2
                                      Where isActive=true
                                      And isStandard=true
                                      Limit 1];

        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        List<PricebookEntry> pbe_list = new List<PricebookEntry>();
        for(Integer i = 0; i < products.size(); i++) {
            PricebookEntry standardPrice = new PricebookEntry(
                                    Pricebook2Id = standardPB.get(0).id,
                                    UnitPrice = 10.0 + Decimal.valueOf(i),
                                    Product2Id = products.get(i).Id,
                                    IsActive = true,
                                    UseStandardPrice = false);
           pbe_list.add(standardPrice);
        }
        insert pbe_list;

        //Create all Typ_av_cases__c options
        String[] typeOfCases = new String[]{'  Ny användare    ',
                                        '   Autoimport av försäljningssiffror   ',
                                        '   Rapportfunktion ',
                                        '   Extra lönekörning   ',
                                        '   Webbschema  '};

        // Create mock cases
        List<Case> cases = TestFactory.buildTestCases(2, accs, conts);
        for(Integer i = 0; i < cases.size(); i++) {
            cases.get(i).Status = 'Nytt';
        }
        insert cases;

        for(Integer i = 0; i < cases.size(); i++) {
            cases.get(i).Status = 'Stängt';
        }
        update cases;

        List<CaseProductObject__c> cpo_list = new List<CaseProductObject__c>();
        for(Integer i = 0; i < cases.size(); i++) {
            CaseProductObject__c cpo = new CaseProductObject__c();
            cpo.Name = 'Test_' + i;
            cpo.Antal__c = i;
            cpo.Enhetspris__c = 10 + Decimal.valueOf(i);
            cpo.Enhet__c = i < products.size()  ? products.get(i).Charging_Period__c : '/month';
            cpo.PriceBookEntry__c =  pbe_list.get(0).id;
            cpo.Case__c = cases.get(i).id;
            cpo.Product__c = i < products.size() ? products.get(i).id : products.get(0).id;
            cpo_list.add(cpo);
        }
        insert cpo_list;

        Test.startTest();
        cpo_list.get(0).Antal__c = 99;
        update cpo_list;
        Test.stopTest();

        List<CaseProductObject__c> res_cpo_list = [Select Antal__c, Case__c, PriceBookEntry__c
                                               From CaseProductObject__c
                                               Where id =: cpo_list.get(0).id];

        List<OpportunityLineItem> res_oli_list = [Select id, Quantity From OpportunityLineItem
                                              Where PriceBookEntryId =: res_cpo_list.get(0).PriceBookEntry__c
                                              And OpportunityId =:
                                                [ Select id From Opportunity
                                                  Where Case__c =: cpo_list.get(0).Case__c]
                                              ];
        System.debug('res_oli_list = ' + res_oli_list);
        if(res_oli_list.size() > 0) {
          System.assertEquals(99, res_oli_list.get(0).Quantity);
        }

    }

}