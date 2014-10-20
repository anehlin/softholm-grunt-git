@isTest(SeeAllData=true)
private class Test_CaseProductController {

    //
    // Verify that a CaseProductObject is created with relevant
    // data when adding a product to a current Case
    //
    private static testMethod void createAddProductToCase() {

        // Create mock accounts
        List<Account> accs = TestFactory.buildTestAccounts(1);
        insert accs;

        // Create mock contacts
        List<Contact> conts = TestFactory.buildTestContacts(2, accs);
        insert conts;
        
        // Insert test products.
        List<Product2> products = new List<Product2>();
        for(Integer i = 0; i < 5; i++) {
            Product2 prod = new Product2();
            prod.Name = 'Product_' + String.valueOf(i); 
            prod.Charging_period__c = '/month';
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
        
        // Create mock case
        List<Case> cases = TestFactory.buildTestCases(2, accs, conts);
        Case testCase = cases.get(0);
        insert testCase;

        // Create the LoginCheck page
        PageReference new_case = Page.CaseNew;
        new_case.getParameters().put('Id', testCase.id);

        // Set current page
        Test.setCurrentPage(new_case);
        
         // Instantiate the standard controller and the extension class
         CaseProductController cpc = new CaseProductController();
         
         // Set selected product
         cpc.selectedProduct = products.get(0).id;
         
         // Call other methods
         PageReference samePage = cpc.updatePriceBook();
         cpc.checkProductChoice();
         List<selectOption> pb_selectlist = cpc.getPriceBooks();
         
         //Verify other methods
         System.assertEquals(null, samePage);
         System.assert(pb_selectlist.size() > 0);
         
         //The .getURL will return the page url the saveAndAddProduct() method returns.
         String returnPageWithProduct = cpc.saveAndAddProduct().getUrl();
         String returnPageWithNoProduct = cpc.cancel().getUrl();
         
         //Verify that the detail page for the new case displays
         System.assertEquals('/'+ testCase.id, returnPageWithProduct);
         System.assertEquals('/'+ testCase.id, returnPageWithNoProduct);
   
         List<CaseProductObject__c> cpo_list = [Select id, Name, StartDatum__c, Antal__c, Enhetspris__c,
                              Enhet__c, PriceBookEntry__c, Case__c, Product__c
                              From CaseProductObject__c
                              Where Case__c =: testCase.id];
         
         //Verify that a CaseProductObject__c has been created 
         System.assertEquals(cpo_list.size(), 1);
         System.assertEquals(cpo_list.get(0).Product__c, products.get(0).id);
         
    }    

}