public with sharing class VendorRateCardController {
    // Get the Vendor Account from the Vendor_Account__c input field on the lightning web component
    // Declare the vendorAccountId variable
    public static Id vendorAccountId;

    @AuraEnabled 
    public static void saveCongruexPricingRecords(List<Congruex_Vendor_Pricing__c> records) {

        if(records.size() > 0 && records != null) {
            List<Congruex_Vendor_Pricing__c> pricingRecordsToCreate = new List<Congruex_Vendor_Pricing__c>();

            for(integer i = 0; i < records.size(); i++) {
                Congruex_Vendor_Pricing__c cvp = new Congruex_Vendor_Pricing__c();
                cvp.Id = records[i].Id;
                cvp.Account__c = vendorAccountId;
                cvp.Price_Book_Item__c = records[i].Price_Book_Item__c;
                cvp.Cost__c = records[i].Cost__c;
                pricingRecordsToCreate.add(cvp);
            }
            insert pricingRecordsToCreate;
        }

    }

    // get the current Project Price Book record from the current page
    // get the related Price Book Item records from the current recordId
    public static sitetracker__Project_Price_Book__c getProjectPriceBook(Id recordId) {
        return [
            SELECT Id, Name 
            FROM sitetracker__Project_Price_Book__c 
            WHERE Id = :recordId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static sitetracker__Project_Price_Book__c getProjectPriceBookWithItems(Id recordId) {
        return [
            SELECT Id, Name, 
                (SELECT Id, Name, Price_Book_Name__c, sitetracker__Project_Price_Book__c, sitetracker__Description__c, UOM__c, Price_Per_Unit__c, External_Labor_Cost__c, Sort__c, Price_Book_Item_Status__c, IsActive__c
                 FROM sitetracker__Price_Book_Items__r
                 WHERE IsActive__c = true AND Price_Book_Item_Status__c = 'Effective'
                 ORDER BY Sort__c ASC)
            FROM sitetracker__Project_Price_Book__c 
            WHERE Id = :recordId
        ];
        
    }

    // Get the Vendor Account from the Vendor_Account__c input field on the lightning web component
    @AuraEnabled
    public static Account getVendorAccountId(Id vendorAccountId) {
        return [
            SELECT Id, Name
            FROM Account 
            WHERE Id = :vendorAccountId
        ];
    }

    // Get the Vendor Account Name 
    @AuraEnabled
    public static String getVendorAccountName(Id vendorAccountId) {
        return getVendorAccountId(vendorAccountId).Name;
    }

    // Get the Project Price Book Name
    @AuraEnabled
    public static String getProjectPriceBookName(Id recordId) {
        return getProjectPriceBook(recordId).Name;
    }

    // Get the Project Price Book BU 
    @AuraEnabled
    public static String getProjectPriceBookBU(Id recordId) {
        return getProjectPriceBook(recordId).BU__c;
    }

    // Get the payment terms from the Payment_Terms__c input field on the lightning web component
    @AuraEnabled
    public static String getPaymentTerms(String paymentTerms) {
        return paymentTerms;
    }

    @AuraEnabled
    public static String getContractUrl(String contractUrl) {
        return contractUrl;
    }

    @AuraEnabled
    public static String getOU(String ou) {
        return ou;
    }

    @AuraEnabled
    public static String getVendorAccountType(String vendorAccountType) {
        return vendorAccountType;
    }


    @AuraEnabled
    public static void createVendorRateCardWithItems(Id projectPriceBookId, Id vendorAccount, String contractUrl, String paymentTerms, String ou, List<Map<String, Object>> editedRows) {
        System.debug('========================================THIS IS THE START OF THE CREATE VENDOR RATE CARD METHOD========================================');
        System.debug('projectPriceBookId: ' + projectPriceBookId);
        System.debug('vendorAccountId: ' + vendorAccount);
        System.debug('contractUrl: ' + contractUrl);
        System.debug('paymentTerms: ' + paymentTerms);
        System.debug('ou: ' + ou);
        System.debug('editedRows: ' + editedRows);
        // Create a new Vendor Rate Card record
        Vendor_Rate_Card__c vendorRateCard = new Vendor_Rate_Card__c();
        vendorRateCard.Project_Price_Book__c = projectPriceBookId;
        vendorRateCard.Vendor_Account__c = vendorAccount;

        // Construct the Name and trim if it exceeds 80 characters
        // vendorRateCard.Name = LEFT(getVendorAccountName(vendorAccount) + ' - ' + getProjectPriceBookName(projectPriceBookId), 80);

        vendorRateCard.Name = getVendorAccountName(vendorAccount) + ' - ' + getProjectPriceBookName(projectPriceBookId);
        if (vendorRateCard.Name.length() > 80) {
            vendorRateCard.Name = getVendorAccountName(vendorAccount).substring(0, 30) + ' - ' + getProjectPriceBookName(projectPriceBookId);
        }
        vendorRateCard.Link_to_Contract__c = contractUrl;
        vendorRateCard.Payment_Terms__c = paymentTerms;
        // vendorRateCard.OU__c = ou;

        // Insert the new Vendor Rate Card record
        insert vendorRateCard;
        System.debug('vendorRateCard: ' + vendorRateCard);
        System.assertEquals(vendorRateCard.Vendor_Account__c, vendorAccount);

        // Create a new Congruex Vendor Pricing record for each row that was edited in the LWC datatable and add it to the Vendor Rate Card
        createCongruexPricingRecords(vendorAccount, editedRows, vendorRateCard);
    }

    // Get the list of edited rows of Price Book Items from the LWC datatable. Then create a new child Congruex Vendor Pricing record for each row
    @AuraEnabled
    public static void createCongruexPricingRecords(Id vendorAccount, List<Map<String, Object>> editedRows, Vendor_Rate_Card__c vendorRateCard) {
        System.debug('========================================THIS IS THE START OF THE CREATE CONGRUEX PRICING RECORDS METHOD========================================');    
        System.debug('editedRows: ' + editedRows);
        System.debug('vendorAccount: ' + vendorAccount);
        System.debug('editedRows: ' + JSON.serialize(editedRows));
        List<Congruex_Vendor_Pricing__c> vendorPricingList = new List<Congruex_Vendor_Pricing__c>();
        List<Map<String, Object>> exposedEditedRows = new List<Map<String, Object>>();
        for(Map<String, Object> editedRow: editedRows) {
            // Extract relevant field values from the edited row map
            String priceBookItemId = (String)editedRow.get('priceBookItemId');
            String priceBookItemName = (String)editedRow.get('priceBookItemName');
            String description = (String)editedRow.get('description');
            String uom = (String)editedRow.get('uom');
            String externalLaborCostStr = (String)editedRow.get('externalLaborCost');
            String congruexVendorPriceStr = (String)editedRow.get('congruexVendorPrice');

            if (congruexVendorPriceStr == null || congruexVendorPriceStr == '') {
                congruexVendorPriceStr = '0';
            }

            if (externalLaborCostStr == null || externalLaborCostStr == '') {
                externalLaborCostStr = '0';
            }



            Decimal externalLaborCost = Decimal.valueOf(externalLaborCostStr);
            Decimal congruexVendorPrice = Decimal.valueOf(congruexVendorPriceStr);
           
            // Create a new Congruex Vendor Pricing record and populate the fields
            Congruex_Vendor_Pricing__c vendorPricing = new Congruex_Vendor_Pricing__c (

                Price_Book_Item__c = priceBookItemId,
                Cost__c = congruexVendorPrice,
                Account__c = vendorAccount,
                Vendor_Rate_Card__c = vendorRateCard.Id
            ); 

            // Add the new Congruex Vendor Pricing record to the list
            vendorPricingList.add(vendorPricing);
            System.debug('vendorPricingList: ' + vendorPricingList);

            // Create a map to expose the relevant fields to the LWC datatable
            Map<String, Object> exposedRow = new Map<String, Object>();
            exposedRow.put('priceBookItemId', priceBookItemId);
            exposedRow.put('priceBookItemName', priceBookItemName);
            exposedRow.put('description', description);
            exposedRow.put('uom', uom);
            // exposedRow.put('pricePerUnit', pricePerUnit);

            // Add the exposed row to the list of exposed edited rows
            exposedEditedRows.add(exposedRow);
            System.debug('exposedEditedRows: ' + exposedEditedRows);
            System.debug('exposedEditedRows: ' + JSON.serialize(exposedEditedRows));

        }

        // Insert the list of new Congruex Vendor Pricing records
        insert vendorPricingList;

    }

    @AuraEnabled
    public static void createVendorRateCardWithPricingItems(Id projectPriceBookId, Id vendorAccount, String contractUrl, String paymentTerms, String ou, List<Map<String, Object>> selectedRows) {
        System.debug('========================================THIS IS THE START OF THE CREATE VENDOR RATE CARD WITH PRICING ITEMS METHOD========================================');
        System.debug('projectPriceBookId: ' + projectPriceBookId);
        System.debug('vendorAccountId: ' + vendorAccount);
        
        
        // Create a new Vendor Rate Card record
        Vendor_Rate_Card__c vendorRateCard = new Vendor_Rate_Card__c();
        vendorRateCard.Project_Price_Book__c = projectPriceBookId;
        vendorRateCard.Vendor_Account__c = vendorAccount;
        vendorRateCard.Name = getVendorAccountName(vendorAccount) + ' - ' + getProjectPriceBookName(projectPriceBookId);
        if (vendorRateCard.Name.length() > 80) {
            vendorRateCard.Name = getVendorAccountName(vendorAccount).substring(0, 30) + ' - ' + getProjectPriceBookName(projectPriceBookId);
        }
        vendorRateCard.Link_to_Contract__c = contractUrl;
        vendorRateCard.Payment_Terms__c = paymentTerms;

        // Insert the new Vendor Rate Card record
        insert vendorRateCard;
        System.debug('vendorRateCard: ' + vendorRateCard);

        // Create a list to hold Congruex Vendor Pricing records
        List<Congruex_Vendor_Pricing__c> vendorPricingList = new List<Congruex_Vendor_Pricing__c>();
        // Iterate through selected items

        for (Map<String, Object> row : selectedRows) {
            // Get the Price Book Item Id
            String priceBookItemId = (String)row.get('priceBookItemId');
            Decimal congruexVendorPrice = (Decimal)row.get('congruexVendorPrice') == null ? 0 : (Decimal)row.get('congruexVendorPrice');

                // Create a new Congruex Vendor Pricing record and populate the fields
                Congruex_Vendor_Pricing__c vendorPricing = new Congruex_Vendor_Pricing__c (
                    Price_Book_Item__c = priceBookItemId,
                    Cost__c = congruexVendorPrice,
                    Account__c = vendorAccount,
                    Vendor_Rate_Card__c = vendorRateCard.Id
                ); 

                // Add the new Congruex Vendor Pricing record to the list
                vendorPricingList.add(vendorPricing);
                System.debug('vendorPricing: ' + vendorPricing);
            }

        // Insert the list of new Congruex Vendor Pricing records
        insert vendorPricingList;
        System.debug('vendorPricingList: ' + vendorPricingList);

    }


    // For each Price Book Item added, create child Congruex Vendor Pricing records for each row related to the Vendor Rate Card
    public static void addPriceBookItems(List<sitetracker__Pricebook_Item__c> priceBookItems, Id vendorRateCardId) {
        List<Congruex_Vendor_Pricing__c> vendorPricingList = new List<Congruex_Vendor_Pricing__c>();
        for(sitetracker__Pricebook_Item__c priceBookItem : priceBookItems) {
            Congruex_Vendor_Pricing__c vendorPricing = new Congruex_Vendor_Pricing__c();
            vendorPricing.Vendor_Rate_Card__c = vendorRateCardId;
            vendorPricing.Price_Book_Item__c = priceBookItem.Id;
            vendorPricingList.add(vendorPricing);
        }
        insert vendorPricingList;
    }




}
