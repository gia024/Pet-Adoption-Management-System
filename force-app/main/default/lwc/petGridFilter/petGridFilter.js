import { LightningElement, track, wire } from 'lwc';
import getBreedOptions from '@salesforce/apex/PetGridController.getBreedOptions';

export default class PetGridFilter extends LightningElement {
  selectedBreed = '';
  selectedGender = '';
  minAge = null;
  maxAge = null;
  breedOptions = [];

  get genderOptions() {
    return [
      { label: 'Any', value: '' },
      { label: 'Male', value: 'Male' },
      { label: 'Female', value: 'Female' }
    ];
  }

  @wire(getBreedOptions)
  wiredBreeds({ data, error }) {
    if (data) {
      this.breedOptions = [{ label: 'Any', value: '' }];
      data.forEach(b => {
        this.breedOptions.push({ label: b, value: b });
      });
    } else if (error) {
      console.error('Error loading breeds', error);
    }
  }

  handleInputChange(event) {
    const { name, value } = event.target;
    this[name] = value;
  }

  handleFilterClick() {
    this.dispatchEvent(new CustomEvent('filterchange', {
      detail: {
        breed: this.selectedBreed,
        gender: this.selectedGender,
        minAge: this.minAge,
        maxAge: this.maxAge
      }
    }));
  }

  handleClearClick() {
    this.selectedBreed = '';
    this.selectedGender = '';
    this.minAge = null;
    this.maxAge = null;

    this.dispatchEvent(new CustomEvent('filterchange', {
      detail: {
        breed: '',
        gender: '',
        minAge: null,
        maxAge: null
      }
    }));
  }
}