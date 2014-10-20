public class CaseNewExtension {

    public Case c { get; private set; }
    public ID selectedProduct { get;set; }
    public ID selectedPricebook { get;set; }
    private ID selectedPriceBookEntry { get; set; }
    private Decimal unitPrice { get; set; }
    public Boolean hasNotAddedProduct { get; set; }
    private String productName { get; set; }
    private String unitType { get; set; }
    public String selectedStatus { get; set; }

    // Constructor
    public CaseNewExtension(ApexPages.StandardController stdController) {
        this.c = (Case)stdController.getRecord();
        this.c.OwnerId = UserInfo.getUserId();

        List<Pricebook2> p_book = [SELECT Id FROM Pricebook2
                                  Where Name = 'Standard Price Book'];
        this.selectedPricebook = p_book.get(0).id;
        hasNotAddedProduct = true;
    }

    // Activate the "Lägg till en produkt"-button
    public void checkProductChoice() {
        hasNotAddedProduct = this.selectedProduct != null ? false : true;
    }

    public void AccountPopulated() {
        List<Contact> contacts = [Select AccountId From Contact Where Id =: this.c.ContactId LIMIT 1];
        if(contacts.size() > 0) {
            this.c.AccountId = contacts.get(0).AccountId;
        }
    }

    // Get a list of picklist values from an existing object field.
   public list<SelectOption> getStatusValues()
   {
      list<SelectOption> options = new list<SelectOption>();
      // Get the object type of the SObject.
      Schema.sObjectType objType = case.getSObjectType();
      // Describe the SObject using its object type.
      Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
      // Get a map of fields for the SObject
      map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
      // Get the list of picklist values for this field.
      list<Schema.PicklistEntry> values =
         fieldMap.get('Status').getDescribe().getPickListValues();
      // Add these values to the selectoption list.
      for (Schema.PicklistEntry a : values) {
         if(a.getLabel() != 'Stängt') {
             options.add(new SelectOption(a.getLabel(), a.getValue()));
         }
      }
      return options;
   }

     public List<selectOption> getPriceBooks() {
        List<selectOption> options = new List<selectOption>();

        List<Pricebook2> pb = [SELECT
                                Id, Name
                                FROM Pricebook2];

         for(Pricebook2 p : pb) {
             options.add(new SelectOption(p.Id,p.Name));
         }

         return options;
     }

     public List<selectOption> getProducts() {
        List<selectOption> options = new List<selectOption>();

        List<PricebookEntry> pbe = [SELECT Product2Id, Pricebook2Id, ProductCode, Pricebook2.Name,
                                        Product2.Charging_period__c, Id, Name, UnitPrice
                                        FROM PricebookEntry
                                        Where IsActive = true
                                        And Pricebook2.Id =: this.selectedPricebook];

        String optionName = pbe.size() > 0 ? 'Välj produkt från ' + pbe.get(0).Pricebook2.Name :
                                             'Produkter saknas';

        SelectOption firstOption = new SelectOption('', optionName);
        options.add(firstOption);

        if(pbe.size() > 0) {
            for(PricebookEntry p : pbe) {
                String label = p.Name + ' - ' + p.UnitPrice + p.Product2.Charging_period__c;
                options.add(new SelectOption(p.Product2Id, label));
             }
         }
         return options;
     }

    private void updatePriceBookEntry(ID selectedProduct) {

       List<PriceBookEntry> m_pbe = [SELECT Product2Id, Pricebook2Id, ProductCode, Pricebook2.Name,
                                        Product2.Charging_period__c, Id, Name, UnitPrice
                                        FROM PricebookEntry
                                        Where IsActive = true
                                        And Pricebook2.Id =: this.selectedPricebook
                                        And Product2Id =: selectedProduct ];
      this.selectedPriceBookEntry = m_pbe.get(0).id;
      this.unitPrice = m_pbe.get(0).UnitPrice;
      this.productName = m_pbe.get(0).Name;
      this.unitType = m_pbe.get(0).Product2.Charging_period__c;
    }

    public PageReference updatePriceBook() {
        this.getProducts();
        return null;
    }

     public PageReference saveAndAddProduct() {

       updatePriceBookEntry(this.selectedProduct);

       try{
            this.c.Status = this.selectedStatus;
            insert this.c;
            CaseProductObject__c cpo = new CaseProductObject__c();
            cpo.Name = this.productName;
            cpo.StartDatum__c = this.c.StartDate__c;
            cpo.Antal__c = this.c.Antal__c > 0 ? this.c.Antal__c : 1.0;
            cpo.Enhetspris__c = unitPrice;
            cpo.Enhet__c = unitType;
            cpo.PriceBookEntry__c = this.selectedPriceBookEntry;
            cpo.Case__c = this.c.id;
            cpo.Product__c = this.selectedProduct;
            insert cpo;
        }
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR,'Error creating/updating record'));
        }

        PageReference pageRef = new PageReference('/'+ this.c.id);
        pageRef.setRedirect(true);

        return pageRef;
    }

}