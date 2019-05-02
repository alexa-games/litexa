export interface TimeService {
    serverTimeGetDay(date?: Date): number;
}

export const Time: TimeService = {
    serverTimeGetDay: (date = new Date()): number => {
        return date.getDay();
    }
};
