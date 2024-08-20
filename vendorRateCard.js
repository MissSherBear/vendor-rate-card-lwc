import { LightningElement, wire, track, api } from 'lwc';
import getProjectPriceBookWithItems from '@salesforce/apex/VendorRateCardController.getProjectPriceBookWithItems';
import createCongruexPricingRecords from '@salesforce/apex/VendorRateCardController.createCongruexPricingRecords';
import createVendorRateCardWithItems from '@salesforce/apex/VendorRateCardController.createVendorRateCardWithItems';
import createVendorRateCardWithPricingItems from '@salesforce/apex/VendorRateCardController.createVendorRateCardWithPricingItems';
import saveCongruexPricingRecords from '@salesforce/apex/VendorRateCardController.saveCongruexPricingRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import BU_FIELD from '@salesforce/schema/sitetracker__Project_Price_Book__c.BU__c';
import ACCOUNT_BU_FIELD from '@salesforce/schema/Account.BU__c';
import VENDOR_ACCOUNT_TYPE from '@salesforce/schema/Account.Vendor_Account_Type__c';
import { setTimeoutPromise } from '@salesforce/apex';

export default class VendorRateCard extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track pricingRecords = [];
    @api sitetrackerProjectPriceBook;
    @track updatedRows = [];
    @track editedRows = [];
    draftValues = [];
    vendorAccount;
    contractUrl;
    paymentTerms;
    ou;
    selection;
    selectedRows = [];
    @track myList = [];
    bu;
    vendorAccountOu;
    vendorAccountType;
    loadMoreStatus;
    data = [];
    @api totalNumberOfRows;


    columns = [ 
        { label: 'Price Book Item', fieldName: 'priceBookItemName', type: 'text', sortable: true, hideDefaultActions: true },
        { label: 'Description', fieldName: 'description', fixedWidth: 300, hideDefaultActions: true},
        { label: 'UOM', fieldName: 'uom', hideDefaultActions: true},
        { label: 'Price Per Unit', fieldName: 'pricePerUnit', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
        { label: 'Ext. Labor Cost', fieldName: 'externalLaborCost', type: 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
        { label: 'Vendor Price', fieldName: 'congruexVendorPrice', type: 'currency', editable: true, hideDefaultActions: true, cellAttributes: { alignment: 'right' }, typeAttributes: { currencyCode: 'USD' }},
            // { type: 'button-icon', typeAttributes: { iconName: 'utility:edit', label: 'Edit', name: 'edit' } }
        // {type: 'button', typeAttributes: {label: 'Edit', name: 'edit', iconName: 'utility:edit'}, hideDefaultActions: true }
        { hideDefaultActions: true, fixedWidth: 50}
    ];

    // renderedCallback() {
    //     if (this.isLoaded) return;
    //     const STYLE = document.createElement('style');
    //     STYLE.innerText = `.uiModal--medium .modal-container {
    //         width: 100% !important;
    //         max-width: 100%;
    //         min-width: 480px;
    //         max-height: 100%;
    //         min-height: 480px;
    //     }`;
    //     this.template.querySelector('lightning-card').appendChild(STYLE);
    //     this.isLoaded = true;

    //     }

    

    getSelectedName(event) {
        const selectedRows = event.detail.selectedRows;
        // Display the fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++){
            
            console.log("selectedRows: " + selectedRows[i].priceBookItemName);
            this.selectedRows.push(selectedRows[i]);
            console.log('pushed selectedRows', this.selectedRows);
            // console.log(JSON.stringify(selectedRows[i], null, '\t'));
            // console.log('Selected Rows', JSON.stringify(this.selectedRows, null, 4));
        }

    }

    loadMoreData(event) {
        event.target.isLoading = true;
        this.loadMoreStatus = 'Loading';

        setTimeoutPromise(3000)
        }

        




    @wire(getProjectPriceBookWithItems, { recordId: '$recordId' })
    wiredPriceBookItems({ error, data }) {
        console.log('recordId', this.recordId);

        if (data) {
            this.pricingRecords = [];
            // Check if sitetracker__Price_Book_Items__r exists in data
        if (data.sitetracker__Price_Book_Items__r) {
            data.sitetracker__Price_Book_Items__r.forEach(priceBookItem => {
                let vendorPrice = null; 
                // Check if the vendorAccount Type is Standard
                

                if (priceBookItem.External_Labor_Cost__c && this.vendorAccountType === 'Standard') {
                    vendorPrice = priceBookItem.External_Labor_Cost__c;
                }
                // Push the necessary fields to pricingRecords array
                this.pricingRecords.push({
                    priceBookItemId: priceBookItem.Id,
                    priceBookItemName: priceBookItem.Name,
                    description: priceBookItem.sitetracker__Description__c,
                    uom: priceBookItem.UOM__c,
                    pricePerUnit: priceBookItem.Price_Per_Unit__c,
                    externalLaborCost: priceBookItem.External_Labor_Cost__c,
                    congruexVendorPrice: vendorPrice
                });
            });
        }

        console.log('pricingRecords', this.pricingRecords);
        console.log('Pricing Records', JSON.stringify(this.pricingRecords, null, 4));


        } else if (error) {

            this.error = error;
            this.pricingRecords = undefined;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [BU_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.bu = getFieldValue(data, BU_FIELD);
            console.log('BU', this.bu);
            this.checkAccountBu();
        } else if (error) {
            console.error('Error loading Project Price Book record', error);
        }
    }

    // Method to fetch the Account BU from the vendorAccount
    @wire(getRecord, { recordId: '$vendorAccount', fields: [ACCOUNT_BU_FIELD, VENDOR_ACCOUNT_TYPE] })
    wiredAccount({ error, data }) {
        if (data) {
            this.vendorAccountOu = getFieldValue(data, ACCOUNT_BU_FIELD);
            this.vendorAccountType = getFieldValue(data, VENDOR_ACCOUNT_TYPE);
            console.log('wired vendorAccountOu', this.vendorAccountOu);
            console.log('wired vendorAccountType', this.vendorAccountType);
            this.validateBUandOU();

            // Check if the vendorAccount Type is Standard
            if (this.vendorAccountType === 'Standard') {
                this.pricingRecords = this.pricingRecords.map(priceBookItem => {
                    if (priceBookItem.externalLaborCost) {
                        priceBookItem.congruexVendorPrice = priceBookItem.externalLaborCost;
                    }
                    return priceBookItem;
                });
            }

        } else if (error) {
            console.error('Error loading Account record', error);
        }
    }

    checkAccountBu() {
        if (this.vendorAccountOu && this.bu) {
            if (this.vendorAccountOu !== this.bu) {
                this.vendorAccountError = 'The Vendor Account Operating Unit does not match the Project Price Book Business Unit';
            } else {
                this.vendorAccountError = '';
            }            
        }
    }


    connectedCallback() {
        getProjectPriceBookWithItems({ recordId: this.recordId })

            .then(result => {
                // handle the result
                console.log('connectedCallback result: ', result);

            })
            .catch(error => {
                // handle the error
                console.log('connectedCallback error: ', error);
            });
    }

    showFirstScreen = true;
    showSecondScreen = false;

    handleVendorAccountChange(event) {
        this.vendorAccount = event.target.value;

        console.log('handleVendorAccountChange vendorAccount: ', event.target.value);
        console.log('BU', this.bu);
        console.log('this.vendorAccountOu', this.vendorAccountOu);
        console.log('this.vendorAccountType', this.vendorAccountType);
        this.checkAccountBu();
    }

    validateBUandOU() {
        if (this.vendorAccountOu && this.bu) {
            if (this.vendorAccountOu !== this.bu) {
                this.vendorAccountError = 'The Vendor Account Operating Unit does not match the Project Price Book Business Unit';
            } else if (this.vendorAccountOu == null) {
                this.vendorAccountError = '';
            } else {
                this.vendorAccountError = '';
            }
        }
    }

    handleUrlChange(event) {
        this.contractUrl = event.target.value;
        console.log('handleUrlChange contractUrl: ', event.target.value);
    }

    handlePaymentTermsChange(event) {
        this.paymentTerms = event.target.value;
        console.log('handlePaymentTermsChange paymentTerms: ', event.target.value);
    }

    // handleOperatingUnitChange(event) {
    //     this.ou = event.target.value;
    //     console.log('handleOperatingUnitChange ou: ', event.target.value);
    // }




    // handleCellChange() {
    //     // Query the DOM for editable cells
    //     const isEdited = Array.from(this.template.querySelectorAll('lightning-datatable') 
    //     )
    //     // Filter the cells that have been edited and have a value
    //     .filter((cell) => cell.draftValue !== undefined && cell.draftValue !== null)
    //     // Map the edited cells to an object with the field name and value
    //     .map((cell) => {
    //         return {
    //             fieldName: cell.fieldName,
    //             value: cell.draftValue
    //         };
    //     });
    //     this.selection = isEdited.join(', ');
    //     console.log('handleCellChange selection: ', this.selection);
    // }

    handlePricingChange() {
        // Query the DOM for editable cells
        const isEdited = Array.from(this.template.querySelectorAll('lightning-datatable') 
        )
        // Filter the cells that have been edited and have a value
        .filter((cell) => cell.draftValue !== undefined && cell.draftValue !== null)
        // Map the edited cells to an object with the field name and value
        .map((cell) => {
            return {
                fieldName: cell.fieldName,
                value: cell.draftValue
            };
        });
        this.selection = isEdited.join(', ');
        console.log('handlePricingChange selection: ', this.selection);
    }

    handleNext() {
        this.showFirstScreen = false;
        this.showSecondScreen = true;

        // Get the data from the first screen input fields
        this.vendorAccount = 
        console.log('handleNext vendorAccount: ', this.vendorAccount);
        let draftValues = this.template.querySelector('lightning-datatable').draftValues;
        console.log('draftValues', draftValues);

        // Push the draftValues to the draftValues array
        this.draftValues.push(draftValues);
    }

    // Get the data from the first screen input fields 
    get vendorRateCardFields() {
        return this.template.querySelectorAll('lightning-input');

    }

    handlePrevious() {
        this.showFirstScreen = true;
        this.showSecondScreen = false;


    }

    handleSave(event) {
        let draftValues = this.template.querySelector('lightning-datatable').draftValues;
        console.log('data', this.template.querySelector('lightning-datatable').data);
        console.log('draftValues', draftValues);

        const editedRows = event.detail.draftValues;
        console.log('editedRows = event.detail.draftValues: ', editedRows);
        console.log('this.editedRows ::: '+JSON.stringify(this.editedRows));
        console.log('this.draftValues ::: '+JSON.stringify(this.draftValues));



        if (editedRows.length > 0) {
           // createCongruexPricingRecords({ editedRows: editedRows })
            console.log('createCongruexPricingRecords editedRows: ', editedRows);
        }
    }

    async handleSave3(event) {
        // Pass the edited fields to the createCongruexPricingRecords Apex method
        const updatedFields = event.detail.draftValues;
        console.log('handleSave3 updatedFields', updatedFields);

        try {
            await createCongruexPricingRecords({ editedRows: updatedFields });
            console.log(JSON.stringify('Apex update result: ', updatedFields));
        } catch (error) {
            console.error('Apex update error: ', error);

        }

    }

    handleSaveSelected() {
        // Filter selected rows
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        console.log('selectedRows', selectedRows);
        
        const itemsToCreate = selectedRows.map(row => ({
            priceBookItemId: row.priceBookItemId,
            congruexVendorPrice: row.congruexVendorPrice
        }));

        console.log('itemsToCreate', itemsToCreate);

        // Call the Apex method to create the Vendor Rate Card with Pricing Items
        createVendorRateCardWithPricingItems({ 
            projectPriceBookId: this.recordId,
            vendorAccount: this.vendorAccount,
            contractUrl: this.contractUrl,
            paymentTerms: this.paymentTerms,
            selectedRows: itemsToCreate
        })

        // createVendorRateCardWithPricingItems({ selectedRows: itemsToCreate })

            .then(result => {
                // handle the result
                console.log('result', result);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'The Vendor Rate Card with Congruex Vendor Pricing records has been created successfully',
                        variant: 'success'
                    })
                );
                // Close the modal
                this.dispatchEvent(new CloseActionScreenEvent());

            })
            .catch(error => {
                // handle the error
                console.log('error', error);

                let errorMessage = 'An error occurred while creating the Vendor Rate Card';

                if (Array.isArray(error.body)) {
                    errorMessage = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    errorMessage += error.body.message;
                } else if (error.body.output && typeof error.body.output.errors === 'object') {
                    errorMessage += error.body.output.errors.map(e => e.message).join(', ');
                } else if (error.body.fieldErrors && typeof error.body.fieldErrors === 'object') {
                    // Check if there are fieldErrors
                    errorMessage = Object.values(error.body.fieldErrors)
                        .map(fieldError => fieldError.map(e => e.message).join(', '))
                        .join(', ');
                } else {
                    errorMessage += JSON.stringify(error.body);
                }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating Vendor Rate Card with Pricing Items',
                            message: errorMessage,
                            variant: 'error',
                            mode: 'sticky'

                        })
                    );
                }
            ); 

    }


    handleConfirmCreate() {
        console.info({updatedRows : this.updatedRows});
        // Call the Apex method to create the Vendor Rate Card with Items
        createVendorRateCardWithItems({ 
            vendorAccount: this.vendorAccount,
            projectPriceBookId: this.recordId,
            contractUrl: this.contractUrl,
            paymentTerms: this.paymentTerms,
            editedRows: this.updatedRows
        })
            .then(result => {
                // handle the result
                console.log('result', result);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'The Vendor Rate Card with Congruex Vendor Pricing records has been created successfully',
                        variant: 'success'
                    })
                );
                // Close the quick action modal
                this.dispatchEvent(new CloseActionScreenEvent());

            })
            .catch(error => {
                // handle the error
                console.log('error', error);

                let errorMessage = 'An error occurred while creating the Vendor Rate Card';

                if (Array.isArray(error.body)) {
                    errorMessage = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    errorMessage += error.body.message;
                } else if (error.body.output && typeof error.body.output.errors === 'object') {
                    errorMessage += error.body.output.errors.map(e => e.message).join(', ');
                } else if (error.body.fieldErrors && typeof error.body.fieldErrors === 'object') {
                    // Check if there are fieldErrors
                    errorMessage = Object.values(error.body.fieldErrors)
                        .map(fieldError => fieldError.map(e => e.message).join(', '))
                        .join(', ');
                } else {
                    errorMessage += JSON.stringify(error.body);
                }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating Vendor Rate Card with Pricing Items',
                            message: errorMessage,
                            variant: 'error',
                            mode: 'sticky'

                        })
                    );
                }
            );
    }





    handleCellChange(event) {
        // debugger;
        // Get the updated row
        const updatedRow = event.detail.draftValues[0];
        console.log({detail: event.detail});
        console.log('updatedRow', updatedRow);
        this.updatedRows.push(updatedRow);
        
        
        // Initialize an object to store the field values for the updated row
        // let editedRow = {};

        // // Iterate over the fields in the updated row and add them to the editedRow object
        // for (let field in updatedRow) {
        //     if (field !== 'Id') {
        //         editedRow[field] = updatedRow[field];
        //     }
        // }

        // // Add the fields to the editedRow object
        // editedRow.Id = updatedRow.Id;

        // // Add the updated row to the updatedRows array
        // this.updatedRows.push(updatedRow);
        // console.log('handleCellChange updatedRows', this.updatedRows);
    }


    handleSave2() {
        // this.updatedRows = event.detail.draftValues;
        console.log('handleSave2 updatedRows', this.updatedRows);

        // Check if there are any edited rows
        if (this.updatedRows.length > 0) {
            // Loop through each edited row
            this.updatedRows.forEach(updatedRow => {
                // Identify the edited row by its unique identifier (key-field)
                const editedRowId = updatedRow.Id;

                // Find the corresponding row in the pricingRecords array
                const editedRowData = this.pricingRecords.find(row => row.Id === editedRowId);
                console.log('editedRowData', editedRowData);

                // Create Congruex Pricing Records for each edited row

                // Call the Apex method to create Congruex Pricing Records
                createCongruexPricingRecords({ 
                    Id: editedRowData.Id, 
                    priceBookItemName: editedRowData.priceBookItemName,
                    congruexVendorPrice: updatedRow.Cost__c,
                    vendorAccount: this.vendorAccount                
                })
                    .then(result => {
                        // handle the result
                        console.log('result', result);
                    })
                    .catch(error => {
                        // handle the error
                        console.log('error', error);

                    });
            });

        }
    }

    handleSave4() {
        let toSaveList = this.myList;
        toSaveList.forEach((element, index) => {
            if (element.Name === '') {
                toSaveList.splice(index, 1);
            }
        });
        console.log('toSaveList', toSaveList);

        this.myList = toSaveList;
        saveCongruexPricingRecords({ records: toSaveList })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records saved',
                        variant: 'success'
                    }),
                )
                getProjectPriceBookWithItems();
            })
            .catch(error => {
                this.error = error;
                this.record = undefined;
                console.log('Error in handleSave4: ', error);
            });
    }

    getPricingRecords() {
        getProjectPriceBookWithItems()
            .then(result => {
                this.record = result;
                for (let i = 0; i < this.record.length; i++) {
                    this.record[i].Price_Book_Item__c = this.record[i].Price_Book_Item__r.Id;
                }
                console.log('this.record', this.record);

                this.myList = this.record;
            })
            .catch(error => {
                this.error = error;
                this.record = undefined;
                console.log('Error in getPricingRecords: ', error);
            });
    }





    handlePricingRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        // Handle the action for a cell that has been edited
        if(action.name === 'edit') {
            // Check if the Congruex Vendor Price has a value
            if (row.congruexVendorPrice) {
                // Get the priceBookItemId for the edited row
                const priceBookItemId = this.getPriceBookItemIdForRow(row.Id);
                console.log('priceBookItemId', priceBookItemId);
                // Add the edited row to the editedRows array
                this.editedRows.push(row);
                console.log('handlePricingRowAction editedRows', this.editedRows);
            }
            

            // Create Congruex Pricing Records for the edited row
        }
    
    }

    handleSelect() {
        const rows = [];
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();

        for (let i = 0; i < selectedRows.length; i++) {
            rows.push(selectedRows[i].priceBookItemName);
        }

        console.log('rows', rows);

    }

    add() {
        let newList = this.myList;
        newList.push({Name: "", Description: "", UOM: "", Price_Per_Unit: "", Congruex_Vendor_Price: "", key: this.myList.length});
        this.myList = newList;
        console.log('add myList', this.myList);
    }

    getPriceBookItemIdForRow(rowId) {
        // Iterate through the pricingRecords array to find the record with the matching row ID
        for (let i = 0; i < this.pricingRecords.length; i++) {
            const record = this.pricingRecords[i];
            if (record.Id === rowId) {
                return record.priceBookItemId;
            }
        }
        return null; // Return null if the row ID is not found
    }

    // Getter function to stringify the object
    get stringifyRows() {
        return this.updatedRows.map(row => JSON.stringify(row));
    }

    get stringifyEditedRows() {
        return this.editedRows.map(row => JSON.stringify(row));
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}

