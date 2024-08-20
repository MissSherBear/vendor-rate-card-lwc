@isTest
private class VendorRateCardControllerTest {

    @testSetup
    static void setup() {
        sitetracker__Project_Template__c template = new sitetracker__Project_Template__c(
            Name = 'Test class Project Template',
            sitetracker__Active__c = true
        );

        insert template;

        // Create test data for Project Price Book
        sitetracker__Project_Price_Book__c testPriceBook = new sitetracker__Project_Price_Book__c(
            Name = 'Test Price Book',
            sitetracker__Project_Template__c = template.Id,
            sitetracker__Active__c = true
            );
        insert testPriceBook;

        // Create test Account (Vendor)
        Account testVendor = new Account(
            Name = 'Test Vendor',
            Type = 'Vendor');
        insert testVendor;

        // Create test Price Book Item
        sitetracker__Pricebook_Item__c testPriceBookItem = new sitetracker__Pricebook_Item__c(
            Name = 'Test Price Book Item',
            sitetracker__Project_Price_Book__c = testPriceBook.Id,
            IsActive__c = true
        );
        insert testPriceBookItem;
    }

    @IsTest
    static void testSaveCongruexPricingRecords() {
        // Create test Congruex Vendor Pricing records
        Account testVendor = [SELECT Id FROM Account LIMIT 1];
        sitetracker__Pricebook_Item__c testPriceBookItem = [SELECT Id FROM sitetracker__Pricebook_Item__c LIMIT 1];
        List<Congruex_Vendor_Pricing__c> records = new List<Congruex_Vendor_Pricing__c>();
        
        Congruex_Vendor_Pricing__c record = new Congruex_Vendor_Pricing__c(
            Price_Book_Item__c = testPriceBookItem.Id,
            Cost__c = 100
        );
        records.add(record);
        
        Test.startTest();
        VendorRateCardController.vendorAccountId = testVendor.Id;
        VendorRateCardController.saveCongruexPricingRecords(records);
        Test.stopTest();

        List<Congruex_Vendor_Pricing__c> results = [SELECT Id, Price_Book_Item__c, Account__c, Cost__c FROM Congruex_Vendor_Pricing__c];
        System.assertEquals(1, results.size());
        System.assertEquals(100, results[0].Cost__c);
        System.assertEquals(testVendor.Id, results[0].Account__c);
    }

    @IsTest
    static void testGetProjectPriceBook() {
        sitetracker__Project_Price_Book__c testPriceBook = [SELECT Id, Name FROM sitetracker__Project_Price_Book__c LIMIT 1];

        Test.startTest();
        sitetracker__Project_Price_Book__c result = VendorRateCardController.getProjectPriceBook(testPriceBook.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(testPriceBook.Id, result.Id);
    }

    @IsTest
    static void testCreateVendorRateCardWithItems() {
        Account testVendor = [SELECT Id FROM Account LIMIT 1];
        sitetracker__Project_Price_Book__c testPriceBook = [SELECT Id FROM sitetracker__Project_Price_Book__c LIMIT 1];
        sitetracker__Pricebook_Item__c testPriceBookItem = [SELECT Id FROM sitetracker__Pricebook_Item__c LIMIT 1];

        List<Map<String, Object>> editedRows = new List<Map<String, Object>>();
        Map<String, Object> row = new Map<String, Object>();
        row.put('priceBookItemId', testPriceBookItem.Id);
        row.put('congruexVendorPrice', '200');
        editedRows.add(row);

        Test.startTest();
        VendorRateCardController.createVendorRateCardWithItems(
            testPriceBook.Id,
            testVendor.Id,
            'https://contract.url',
            'Net 30',
            'Some OU',
            editedRows
        );
        Test.stopTest();

        List<Vendor_Rate_Card__c> vendorRateCards = [SELECT Id, Name, Vendor_Account__c FROM Vendor_Rate_Card__c];
        System.assertEquals(1, vendorRateCards.size());
        System.assertEquals(testVendor.Id, vendorRateCards[0].Vendor_Account__c);

        List<Congruex_Vendor_Pricing__c> vendorPricings = [SELECT Id, Price_Book_Item__c, Cost__c, Vendor_Rate_Card__c FROM Congruex_Vendor_Pricing__c];
        System.assertEquals(1, vendorPricings.size());
    }

    @IsTest
    static void testGetVendorAccountId() {
        Account testVendor = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Account result = VendorRateCardController.getVendorAccountId(testVendor.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(testVendor.Id, result.Id);
    }

    @IsTest
    static void testGetVendorAccountName() {
        Account testVendor = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        String vendorName = VendorRateCardController.getVendorAccountName(testVendor.Id);
        Test.stopTest();

        System.assertEquals(testVendor.Name, vendorName);
    }

}
