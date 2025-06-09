import { LightningElement, track, wire } from 'lwc';
import getFreightMetadata from '@salesforce/apex/FreightChargesController.getFreightMetadata';
import updateFreightMetadata from '@salesforce/apex/FreightChargesController.updateFreightMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class FreightChargesEditor extends LightningElement {
    @track seaFreightData = [];
    @track inlandTransportData = [];
    @track isLoading = false;
    wiredMetadataResult;
    retryCount = 0;

    @wire(getFreightMetadata)
    wiredFreight(result) {
        this.wiredMetadataResult = result;
        const { data, error } = result;

        if (data) {
            this.processData(data);
            this.retryCount = 0;
        } else if (error) {
            this.handleError(error);
        }
    }

    processData(data) {
        let keyCounter = 1;

        // Sea Freight
        this.seaFreightData = [
            this.createFreightRow(keyCounter++, '20 Ft', ['China', 'Vietnam', 'Malaysia']),
            this.createFreightRow(keyCounter++, '40 Ft', ['China', 'Vietnam', 'Malaysia'])
        ];

        // Inland Transport
        this.inlandTransportData = [
            this.createFreightRow(keyCounter++, '20 Ft', ['China', 'Vietnam', 'Malaysia']),
            this.createFreightRow(keyCounter++, '40 Ft', ['China', 'Vietnam', 'Malaysia'])
        ];

        // Map metadata to UI
        data.forEach(record => {
            const country = record.MasterLabel;

            // Sea Freight
            this.seaFreightData.forEach(row => {
                const field = row.containerSize === '20 Ft'
                    ? 'Sea_Frieght_USD_20Ft__c'
                    : 'Sea_Frieght_USD_40Ft__c';

                if (['China', 'Vietnam', 'Malaysia'].includes(country)) {
                    this.updateRowData(row, record, country, field);
                }
            });

            // Inland Transport
            if (['China', 'Vietnam', 'Malaysia'].includes(country)) {
                this.inlandTransportData.forEach(row => {
                    const field = row.containerSize === '20 Ft'
                        ? 'Inland_Transport_INR_20Ft__c'
                        : 'Inland_Transport_INR_40Ft__c';
                    this.updateRowData(row, record, country, field);
                });
            }
        });
    }

    createFreightRow(key, containerSize, countries) {
        const tempValues = {};
        const formattedValues = {};
        const DeveloperNames = {};
        countries.forEach(c => {
            tempValues[c] = null;
            formattedValues[c] = '';
        });

        return { key, containerSize, isEdit: false, tempValues, formattedValues, DeveloperNames };
    }

    updateRowData(row, record, country, field) {
        if (record[field] !== undefined && row.tempValues.hasOwnProperty(country)) {
            row.tempValues[country] = record[field];
            row.formattedValues[country] = this.formatNumber(record[field]);
            row.DeveloperNames[country] = record.DeveloperName;
        }
    }

    formatNumber(value) {
        return value !== null && value !== undefined ? value.toFixed(2) : '';
    }

    handleEdit(event) {
        const key = parseInt(event.target.dataset.key, 10);
        this.toggleEditMode(key, true);
    }

    handleCancel(event) {
        const key = parseInt(event.target.dataset.key, 10);
        this.toggleEditMode(key, false);
    }

    toggleEditMode(key, isEdit) {
        this.seaFreightData = this.seaFreightData.map(row =>
            this.updateRowState(row, key, isEdit)
        );
        this.inlandTransportData = this.inlandTransportData.map(row =>
            this.updateRowState(row, key, isEdit)
        );
    }

    updateRowState(row, key, isEdit) {
        if (row.key === key) {
            const updatedTempValues = isEdit
                ? row.tempValues
                : Object.fromEntries(
                    Object.entries(row.tempValues).map(([country]) => [
                        country,
                        row.formattedValues[country] ? parseFloat(row.formattedValues[country]) : null
                    ])
                );

            return { ...row, isEdit, tempValues: updatedTempValues };
        }
        return row;
    }

    handleValueChange(event) {
        const key = parseInt(event.target.dataset.key, 10);
        const country = event.target.dataset.country;
        const value = event.target.value;

        this.seaFreightData = this.seaFreightData.map(row =>
            this.updateRowValue(row, key, country, value, false)
        );
        this.inlandTransportData = this.inlandTransportData.map(row =>
            this.updateRowValue(row, key, country, value, true)
        );
    }

    updateRowValue(row, key, country, value, isInland) {
        if (row.key === key) {
            const updatedTempValues = { ...row.tempValues };

            if (isInland) {
                // Sync China, Vietnam, Malaysia together
                ['China', 'Vietnam', 'Malaysia'].forEach(c => {
                    updatedTempValues[c] = value ? parseFloat(value) : null;
                });
            } else {
                // Normal update for Sea Freight
                updatedTempValues[country] = value ? parseFloat(value) : null;
            }

            return { ...row, tempValues: updatedTempValues };
        }
        return row;
    }

    async handleSave(event) {
        this.isLoading = true;
        const key = parseInt(event.target.dataset.key, 10);

        try {
            const recordsToUpdate = this.prepareUpdateRecords(key);
            await updateFreightMetadata({ updatedRecords: recordsToUpdate });
            await this.refreshData();
            this.showToast('Success', 'Data updated successfully', 'success');
            this.toggleEditMode(key, false);
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    prepareUpdateRecords(key) {
        const row = [...this.seaFreightData, ...this.inlandTransportData]
            .find(r => r.key === key);
        const records = [];

        if (this.seaFreightData.some(r => r.key === key)) {
            // Sea Freight
            ['China', 'Vietnam', 'Malaysia'].forEach(country => {
                if (row.DeveloperNames[country]) {
                    const field = row.containerSize === '20 Ft'
                        ? 'Sea_Frieght_USD_20Ft__c'
                        : 'Sea_Frieght_USD_40Ft__c';

                    if (row.tempValues[country] !== null) {
                        records.push({
                            DeveloperName: row.DeveloperNames[country],
                            MasterLabel: country,
                            [field]: row.tempValues[country]
                        });
                    }
                }
            });
        } else {
            // Inland Transport — update all three countries together
            const field = row.containerSize === '20 Ft'
                ? 'Inland_Transport_INR_20Ft__c'
                : 'Inland_Transport_INR_40Ft__c';

            ['China', 'Vietnam', 'Malaysia'].forEach(country => {
                if (row.DeveloperNames[country] && row.tempValues[country] !== null) {
                    records.push({
                        DeveloperName: row.DeveloperNames[country],
                        MasterLabel: country,
                        [field]: row.tempValues[country]
                    });
                }
            });
        }

        return records;
    }

    async refreshData() {
        try {
            await refreshApex(this.wiredMetadataResult);
            await new Promise(resolve => setTimeout(resolve, 1000));
            const freshData = await getFreightMetadata();
            this.processData(freshData);
            await refreshApex(this.wiredMetadataResult);
        } catch (error) {
            if (this.retryCount < 1) {
                this.retryCount++;
                await new Promise(resolve => setTimeout(resolve, 1000));
                await this.refreshData();
            } else {
                throw error;
            }
        }
    }

    handleError(error) {
        const message = error.body?.message || error.message || 'Unknown error';
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}