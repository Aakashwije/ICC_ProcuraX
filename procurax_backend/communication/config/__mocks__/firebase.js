// Mock Firestore document reference
const mockDoc = jest.fn(() => ({
  get: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
}));

// Mock Firestore collection reference
const mockCollection = jest.fn(() => ({
  add: jest.fn(),
  doc: mockDoc,
  where: jest.fn().mockReturnThis(),
  orderBy: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  get: jest.fn(),
}));

// Mock Firestore batch
const mockBatch = jest.fn(() => ({
  set: jest.fn(),
  commit: jest.fn().mockResolvedValue(undefined),
}));

export const db = {
  collection: mockCollection,
  batch: mockBatch,
};

// Mock Firebase Storage bucket
export const bucket = {
  name: 'mock-bucket',
  file: jest.fn(() => ({
    save: jest.fn(),
    delete: jest.fn().mockResolvedValue(undefined),  // For controller deleteMessage
  })),
  upload: jest.fn(),
};

// Mock Firebase admin object
export const admin = {
  initializeApp: jest.fn(),
  firestore: jest.fn(() => db),
  storage: jest.fn(() => ({ bucket })),
};