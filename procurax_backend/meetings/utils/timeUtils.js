exports.isOverlapping = (start1, end1, start2, end2) => {
  return start1 < end2 && start2 < end1;
};
