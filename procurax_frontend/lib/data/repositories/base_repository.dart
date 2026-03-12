/**
 * Base Repository Interface
 * 
 * Abstract class defining the repository pattern contract.
 * All repositories should extend this class.
 */

abstract class BaseRepository<T> {
  /// Get all items
  Future<List<T>> getAll();

  /// Get single item by ID
  Future<T?> getById(String id);

  /// Create new item
  Future<T> create(T item);

  /// Update existing item
  Future<T> update(String id, T item);

  /// Delete item by ID
  Future<bool> delete(String id);
}
