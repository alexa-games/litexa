import {expect} from 'chai';
import {addNumbers, todayName} from './utils';

describe('utils', () => {
    describe('#todayName', () => {
        it('returns the days of the week correctly', () => {
            expect(todayName(new Date(Date.parse('Jan 6 2019')))).to.equal('Sunday');
            expect(todayName(new Date(Date.parse('Jan 7 2019')))).to.equal('Monday');
            expect(todayName(new Date(Date.parse('Jan 8 2019')))).to.equal('Tuesday');
            expect(todayName(new Date(Date.parse('Jan 9 2019')))).to.equal('Wednesday');
            expect(todayName(new Date(Date.parse('Jan 10 2019')))).to.equal('Thursday');
            expect(todayName(new Date(Date.parse('Jan 11 2019')))).to.equal('Friday');
            expect(todayName(new Date(Date.parse('Jan 12 2019')))).to.equal('Saturday');
        });
    });
    describe('#addNumbers', () => {
        it('defaults to 0', () => {
            expect(addNumbers()).to.equal(0);
        });
        it('sums correctly', () => {
            expect(addNumbers(1,2,3)).to.equal(6);
        });
    });
});
