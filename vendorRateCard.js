import { LightningElement, wire, api, track } from 'lwc';
import getProjectPriceBookWithItems from '@salesforce/apex/VendorRateCardController.getProjectPriceBookWithItems';
import createVendorRateCardWithItems from '@salesforce/apex/VendorRateCardController.createVendorRateCardWithItems';
import getVendorAccount from '@salesforce/apex/VendorRateCardController.getVendorAccount';
import getVendorAccountOu from '@salesforce/apex/VendorRateCardController.getVendorAccountOu';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class VendorRateCard extends LightningElement {

    @api recordId;

    @track pricingRecords = [];
    @track filteredPricingRecords = [];
    @track editedRatePreview = [];
    @track countOfEditedRows = 0;
    @track draftValues = [];

    @track isSaveDisabled = true;
    @track showFirstScreen = true;
    @track showSecondScreen = false;
    @track showConfirmationScreen = false;
    @track createdRecords = [];

    @track vendorAccount;
    @track vendorAccountOu;
    @track paymentTerms;
    @track contractUrl;
    @track vendorRateCardName;
    @track projectPriceBookName;

    editedMap = {};

    columns = [
        { label: 'Price Book Item', fieldName: 'priceBookItemName', type: 'text' },
        { label: 'Description', fieldName: 'description', type: 'text' },
        { label: 'UOM', fieldName: 'uom', type: 'text' },
        { label: 'Price Per Unit', fieldName: 'pricePerUnit', type: 'currency' },
        { label: 'Ext. Labor Cost', fieldName: 'externalLaborCost', type: 'currency' },
        { label: 'Vendor Rate', fieldName: 'congruexVendorPrice', type: 'currency', editable: true, cellAttributes: { iconName: 'utility:edit', iconPosition: 'right' } }
    ];

    connectedCallback() {
        this.loadPricing();
    }

    congruexVendorPriceMap = new Map();

    loadPricing() {
        getProjectPriceBookWithItems({ recordId: this.recordId })
            .then(projectPB => {

                const items = projectPB.sitetracker__Price_Book_Items__r || [];
                console.log('Loaded pricing items:', items);
                console.log('Project Price Book:', projectPB);

                this.pricingRecords = items.map(item => ({
                    priceBookItemId: item.Id,
                    priceBookItemName: item.Name,
                    description: item.sitetracker__Description__c,
                    uom: item.UOM__c,
                    pricePerUnit: item.Price_Per_Unit__c || 0,
                    externalLaborCost: item.External_Labor_Cost__c || null
                }));
                this.filteredPricingRecords = [...this.pricingRecords];
                this.updateSaveButtonState();
                console.log('Filtered pricing records:', this.filteredPricingRecords);
            })
            .catch(error => {
                console.error('Error loading pricing:', error);
            });
    }

    handleVendorAccountChange(event) {
    this.vendorAccount = event.target.value;
    console.log('Selected vendor account from LWC:', JSON.stringify(event.target.value));


    // Call Apex to get OU for this Account Id
    getVendorAccountOu({ vendorAccount: this.vendorAccount })
        .then(ou => {
            this.vendorAccountOu = ou; // ← use the value returned from Apex
            console.log('Vendor Account OU fetched:', this.vendorAccountOu);
        })
        .catch(error => {
            console.error('Error fetching Vendor Account OU:', error);
        });
    console.log('Vendor Account:', this.vendorAccount);
    }

    handlePaymentTermsChange(event) {
        this.paymentTerms = event.target.value;
        console.log('Payment Terms:', this.paymentTerms);
    }

    handleContractUrlChange(event) {
        this.contractUrl = event.target.value;
    }

    handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        if (searchKey) {
            this.filteredPricingRecords = this.pricingRecords.filter(item =>
                item.priceBookItemName.toLowerCase().includes(searchKey)
            );
        } else {
            this.filteredPricingRecords = [...this.pricingRecords];
        }
        console.log('Filtered pricing records after search:', this.filteredPricingRecords);

        // Reapply the preserved Vendor Rate values after filtering
        this.filteredPricingRecords = this.filteredPricingRecords.map(item => {
            return {
                ...item, 
                congruexVendorPrice: this.editedMap[item.priceBookItemId]?.congruexVendorPrice || item.congruexVendorPrice
            };
        });
        console.log('Filtered pricing records after reapplying vendor rates:', this.filteredPricingRecords);
    }

    handleVendorRateChange(event) {
        const id = event.target.dataset.id;
        const vendorPrice = event.target.value;
        
        let row = this.pricingRecords.find(r => r.priceBookItemId === id);
        if (row) {                
            row.congruexVendorPrice = vendorPrice;

            // Only include rows in editedMap if congruexVendorPrice is not null or empty
            if (vendorPrice !== null && vendorPrice !== '' && !isNaN(vendorPrice)) {
                row.isEdited = true;
                row.rowClass = 'edited-cell';  // <-- assign class here
                this.editedMap[id] = { ...row };
            } else {
                // If the vendorPrice is cleared, remove from editedMap
                delete this.editedMap[id];
                row.isEdited = false;
                row.rowClass = '';  // <-- clear class here
            }
        }

        this.filteredPricingRecords = this.filteredPricingRecords.map(item => 
            (item.priceBookItemId === id ? { ...item, congruexVendorPrice: vendorPrice } : item)
        );
        this.updateSaveButtonState();
        console.log('handleVendorRateChange:', vendorPrice);
        console.log('handleVendorRateChange Updated editedMap:', JSON.stringify(this.editedMap));
        console.log('handleVendorRateChange Updated row:', row);
    }

    handleCellChange(event) {
        const id = event.target.dataset.id;
        const value = event.target.value;

        let row = this.pricingRecords.find(r => r.priceBookItemId === id);
        // Filter out null or empty values from editedMap
        if (row) {
            row.congruexVendorPrice = value;
            // Only include rows in editedMap if congruexVendorPrice is not null or empty
            if (value !== null || value !== '') {
                row.isEdited = true;
                row.rowClass = 'edited-cell';  // <-- assign class here
                this.editedMap[id] = { ...row };
            } else {
                // If the value is cleared, remove from editedMap
                delete this.editedMap[id];
                row.isEdited = false;
                row.rowClass = '';  // <-- clear class here
            }
        }
        this.filteredPricingRecords = this.filteredPricingRecords.map(item => 
            (item.priceBookItemId === id ? { ...item, congruexVendorPrice: value } : item)
        );
        console.log('handleCellChange:', value);
        console.log('handleCellChange Updated editedMap:', JSON.stringify(this.editedMap));
        console.log('handleCellChange Updated row:', row);
    }

    goToReview() {
        this.editedRatePreview = Object.values(this.editedMap);
        console.log('Edited rows going to confirmation:', JSON.stringify(this.editedRatePreview));
        console.log('Count of edited rows:', this.editedRatePreview.length);
        console.log('Edited rows formatted:', JSON.stringify(this.editedRatePreview.map(r => ({ ...r, rowClass: r.rowClass }))));
        // Format the array in the console log to show individual objects clearly
        this.editedRatePreview.forEach(r => console.log(JSON.stringify(r)));
        this.showFirstScreen = false;
        this.showSecondScreen = true;
    }

    goBack() {
        // Return to first screen and retain values inputted for vendor rates
        this.filteredPricingRecords = this.pricingRecords.map(item => {
            return {
                ...item, 
                congruexVendorPrice: this.editedMap[item.priceBookItemId]?.congruexVendorPrice || item.congruexVendorPrice
            };
        });
        console.log('Returning to first screen, filtered pricing records:', this.filteredPricingRecords);
    
        this.showFirstScreen = true;
        this.showSecondScreen = false;
        this.showConfirmationScreen = false;
    }

    updateSaveButtonState() {
        this.isSaveDisabled = this.editedRatePreview.every(item => !item.congruexVendorPrice || item.congruexVendorPrice <= 0);
    }

    handleDraftSave(event) {
        this.draftValues = event.detail.draftValues;
        console.log('Draft values:', this.draftValues);

        // Update the editedMap with the new values
        this.draftValues.forEach(draft => {
            const id = draft.priceBookItemId;
            let row = this.pricingRecords.find(r => r.priceBookItemId === id);
            if (row) {
                row.congruexVendorPrice = draft.congruexVendorPrice;

                this.editedMap[id] = { ...row };

                // Mark row as edited
                row.isEdited = true;
                row.rowClass = 'edited-cell';  // <-- assign class here
                this.filteredPricingRecords = this.filteredPricingRecords.map(item =>
                    (item.priceBookItemId === id ? { ...item, congruexVendorPrice: draft.congruexVendorPrice } : item)
                );
            }
        });
        console.log('Updated editedMap:', JSON.stringify(this.editedMap));
        this.draftValues = [];
        
        this.editedRatePreview.forEach(r => {
            r.rowClass = '';  // <-- clear class here
        });
    }

    saveRates() {
        this.editedRatePreview = Object.values(this.editedMap);
        this.countOfEditedRows = this.editedRatePreview.length;
        console.log('Edited rows going to confirmation:', JSON.stringify(this.editedRatePreview));

        console.log('Saving rates for vendor account:', this.vendorAccount);
        console.log('Vendor Rate Card Name:', this.vendorRateCardName);
        console.log('Count of pricing records:', this.editedRatePreview.length);
        console.log('countOfEditedRows:', this.countOfEditedRows);
        console.log('Pricing records:', this.editedRatePreview);
        console.log('Pricing records (stringified):', JSON.stringify(this.editedRatePreview));

        // Guard: nothing edited
        if (!this.editedRatePreview || this.editedRatePreview.length === 0) {
            console.warn('No edited rows to save.');
            return;
        }
        this.updateSaveButtonState();

        if (this.isSaveDisabled) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter at least one valid Vendor Rate before saving.',
                    variant: 'error',
                })
            );
            return;
        }

        // DO NOT show confirmation screen yet. Wait for Apex success.
        createVendorRateCardWithItems({
            projectPriceBookId: this.recordId,
            vendorAccount: this.vendorAccount,
            contractUrl: this.contractUrl,
            paymentTerms: this.paymentTerms,
            ou: this.vendorAccountOu,
            editedRows: this.editedRatePreview
        })
        .then((result) => {
            // IMPORTANT: result should be List<Map<String,Object>> from Apex
            console.log('Apex returned created pricing rows:', JSON.stringify(result));
            
            this.vendorRateCardName = result?.[0]?.vendorRateCardName;
            console.log('Vendor Rate Card Name:', this.vendorRateCardName);

            // Use Apex return (this is where Name/Id come from)
            this.createdRecords = (result || []).map(r => ({
                ...r,
                recUrl: r.congruexVendorPricingId ? ('/' + r.congruexVendorPricingId) : null
            }));
            console.log('Formatted created records:', JSON.stringify(this.createdRecords));


            // Show success screen now
            this.showFirstScreen = false;
            this.showSecondScreen = false;
            this.showConfirmationScreen = true;

            // Optional refresh behind the scenes
            this.loadPricing();
        })
        .catch(error => {
            console.error('Error saving vendor pricing:', error);

            // Keep user on review screen so they can retry
            this.showFirstScreen = false;
            this.showSecondScreen = true;
            this.showConfirmationScreen = false;
        });
    }

    showConfirmation() {
        this.showFirstScreen = false;
        this.showSecondScreen = false;
        this.showConfirmationScreen = true;

        // Get Vendor Rate Card Name to display
        vendorRateCardName = this.vendorAccount.Name + ' - ' + this.projectPriceBookName;
    }

    handleCloseConfirmation() {
        this.showConfirmationScreen = false;
        window.location.reload();
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    
//     Project_Price_Book__c = {
//     "Id": "a0fcX0000003Jz2QAE",
//     "Name": "CNS-1000500 : Memphis HUT4",
//     "sitetracker__Price_Book_Items__r": [
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000Sw5QAE",
//             "Name": "UG13",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "UG Special Crossing Adder",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 0,
//             "External_Labor_Cost__c": 3.5,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000Sw3QAE",
//             "Name": "Place Strand6.6M Rear Easement Adder",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "All labor and equipment required to install one (1) foot of 6.6M strand. This Unit includes installation of pole attachment hardware and bonding of st",
//             "UOM__c": "ft",
//             "Price_Per_Unit__c": 0,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvDQAU",
//             "Name": "Permitting",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Creation, Submission, Acquisition of Permits including supporting documentation (permit cost is pass through)",
//             "UOM__c": "ft",
//             "Price_Per_Unit__c": 1,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvEQAU",
//             "Name": "AE12",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Intall Riser / U-Guard",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 69.95,
//             "External_Labor_Cost__c": 50,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvFQAU",
//             "Name": "HH-24x36",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Handhole (24x36)",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 0,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvGQAU",
//             "Name": "SP08",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Terminal Port Testing, Power Meter, per port",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 13.99,
//             "External_Labor_Cost__c": 10,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvHQAU",
//             "Name": "UG06",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Each Additional 2\"",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 1.4,
//             "External_Labor_Cost__c": 0.5,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvbQAE",
//             "Name": "AE06",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Aerial, Additional Lash Cable (Any Easement)",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 0.7,
//             "External_Labor_Cost__c": 0.5,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvcQAE",
//             "Name": "AE07",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Overlash Fiber",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 2.45,
//             "External_Labor_Cost__c": 1.75,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvdQAE",
//             "Name": "SP03",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Install splice enclosure C",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 279.82,
//             "External_Labor_Cost__c": 200,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SveQAE",
//             "Name": "AE10",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Rock Anchor",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 118.92,
//             "External_Labor_Cost__c": 85,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvfQAE",
//             "Name": "AE13",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Tree Trimming",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 0.84,
//             "External_Labor_Cost__c": 0.6,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvgQAE",
//             "Name": "AE15",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Install Arm",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 34.98,
//             "External_Labor_Cost__c": 25,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvhQAE",
//             "Name": "SP05",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Install splice Terminal",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 174.89,
//             "External_Labor_Cost__c": 125,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SviQAE",
//             "Name": "SP06",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Install mid sheath access enclosure(ring cut)",
//             "UOM__c": "Each",
//             "Price_Per_Unit__c": 139.91,
//             "External_Labor_Cost__c": 100,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvjQAE",
//             "Name": "UG08",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Missile Bore, pull back one conduit up to 2\"",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 15.39,
//             "External_Labor_Cost__c": 11,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvkQAE",
//             "Name": "UG02",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Bore, up to .75\" OD HDPE Conduit(S)",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 15.39,
//             "External_Labor_Cost__c": 11,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvlQAE",
//             "Name": "UG04.01",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Each Additional .75\"",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 0.7,
//             "External_Labor_Cost__c": 0.5,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvmQAE",
//             "Name": "UG05",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Bore 2\"",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 15.39,
//             "External_Labor_Cost__c": 11,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvnQAE",
//             "Name": "UG07",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Bore, Rock Adder",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 20.99,
//             "External_Labor_Cost__c": 15,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SvoQAE",
//             "Name": "UG12",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Place Terminal  UG",
//             "UOM__c": "Linear FT",
//             "Price_Per_Unit__c": 139.91,
//             "External_Labor_Cost__c": 100,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         },
//         {
//             "sitetracker__Project_Price_Book__c": "a0fcX0000003Jz2QAE",
//             "Id": "a0bcX0000000SumQAE",
//             "Name": "EA-004",
//             "Price_Book_Name__c": "CNS-1000500 : Memphis HUT4",
//             "sitetracker__Description__c": "Scoping - Design - AER FT",
//             "UOM__c": "ft",
//             "Price_Per_Unit__c": 0,
//             "Sort__c": 4,
//             "Price_Book_Item_Status__c": "Effective",
//             "IsActive__c": true
//         }
//     ]
// }
}
