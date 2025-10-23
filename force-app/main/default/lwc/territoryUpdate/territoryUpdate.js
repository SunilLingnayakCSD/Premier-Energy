import { LightningElement, track, wire,api } from 'lwc';
import getAccountsWithAddresses from '@salesforce/apex/TerritoryUpdate.getAccountsWithAddresses';
import getAddressesForAccount from '@salesforce/apex/TerritoryUpdate.getAddressesForAccount';
import updateAOP from '@salesforce/apex/TerritoryUpdate.updateAOP';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';


export default class TerritoryUpdate extends LightningElement {
   @api recordId;
    @track accountOptions = [];
    @track selectedAccountId = '';
    @track searchTerm = '';
    @track territoryOptions = [];
    @track selectedTerritory = '';
    @track accounts = [];

    @wire(getAccountsWithAddresses)
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data;
            this.updateAccountOptions();
        } else if (error) {
            console.error('Error fetching accounts', error);
        }
    }

    updateAccountOptions() {
        this.accountOptions = this.accounts
            .filter(acc =>
                this.searchTerm === '' ||
                acc.Name.toLowerCase().includes(this.searchTerm.toLowerCase()))
            .map(acc => ({
                label: acc.Name,
                value: acc.Id
            }));
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.updateAccountOptions();
    }

    handleAccountChange(event) {
        this.selectedAccountId = event.detail.value;
        this.selectedTerritory = '';
        this.territoryOptions = [];

        if (this.selectedAccountId) {
            getAddressesForAccount({ accountId: this.selectedAccountId })
                .then(addresses => {
                    const territories = new Set();
                    addresses.forEach(addr => {
                        if (addr.Territory__c) {
                            territories.add(addr.Territory__c);
                        }
                    });

                    this.territoryOptions = Array.from(territories).map(territory => ({
                        label: territory,
                        value: territory
                    }));
                })
                .catch(error => {
                    console.error('Error fetching addresses', error);
                });
        }
    }

    handleTerritoryChange(event) {
        this.selectedTerritory = event.detail.value;
    }

     handleSave() {
        if (!this.selectedAccountId || !this.selectedTerritory) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Information',
                message: 'Please select both Account and Territory.',
                variant: 'warning'
            }));
            return;
        }

        updateAOP({
            recordId: this.recordId,
            accountId: this.selectedAccountId,
            territory: this.selectedTerritory
        })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'AOP record updated successfully.',
                    variant: 'success'
                }));

                // Optionally close quick action
                    
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }

}