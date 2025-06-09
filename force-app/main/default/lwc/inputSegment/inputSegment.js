// inputSegment.js
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSegmentMetadata from '@salesforce/apex/segmentApexClass.metadataUpdate';
import updateSegmentMetadata from '@salesforce/apex/segmentApexClass.updateMetadata';

export default class InputSegment extends LightningElement {
    segments = [];
    originalValues = [];

    @wire(getSegmentMetadata)
    wiredMetadata({data, error}) {
        if (data) {
            this.segments = data.map(record => ({
                developerName: record.DeveloperName,
                masterLabel: record.MasterLabel,
                dcr: record.DCR__c,
                ndcr: record.NDCR__c,
                isEditing: false
            }));
            // Deep clone for original values
            this.originalValues = JSON.parse(JSON.stringify(this.segments));
        } else if (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        }
    }

    handleEdit(event) {
        const devName = event.target.dataset.id;
        this.segments = this.segments.map(segment => 
            segment.developerName === devName ? {...segment, isEditing: true} : segment
        );
    }

    handleValueChange(event) {
        const devName = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = parseFloat(event.detail.value);
        
        this.segments = this.segments.map(segment => 
            segment.developerName === devName ? {...segment, [field]: value} : segment
        );
    }

    async handleSave(event) {
        const devName = event.target.dataset.id;
        try {
            const segment = this.segments.find(s => s.developerName === devName);
            
            await updateSegmentMetadata({
                developerName: devName,
                dcrValue: segment.dcr,
                ndcrValue: segment.ndcr
            });
            
            // Update UI state
            this.segments = this.segments.map(s => 
                s.developerName === devName ? {...s, isEditing: false} : s
            );
            
            // Update original values
            this.originalValues = this.originalValues.map(orig => 
                orig.developerName === devName ? {...segment} : orig
            );
            
            this.showToast('Success', `${segment.masterLabel} updated!`, 'success');
        } catch (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        }
    }

    handleCancel(event) {
        const devName = event.target.dataset.id;
        const original = this.originalValues.find(s => s.developerName === devName);
        this.segments = this.segments.map(segment => 
            segment.developerName === devName ? {...original, isEditing: false} : segment
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(error) {
        return error.body?.message || 
               error.body?.pageErrors?.[0]?.message || 
               error.message || 'Unknown error';
    }
}