import numpy as np
from dataclasses import dataclass
from typing import Tuple


@dataclass
class DataLabelsPair:
    data: np.ndarray
    labels: np.ndarray


@dataclass
class SplittedDataset:
    train: DataLabelsPair
    val: DataLabelsPair
    test: DataLabelsPair


@dataclass
class SplittedIndecies:
    train: np.ndarray
    val: np.ndarray
    test: np.ndarray

    def to_tuple(self):
        return self.train, self.val, self.test


def get_split_indecies(
    ds_size: int, train_perc: float, val_perc: float
) -> SplittedIndecies:
    assert train_perc + val_perc < 1.0

    random_indecies = np.arange(ds_size)
    np.random.shuffle(random_indecies)

    train_indecies, validation_indecies, test_indecies, _ = np.split(
        random_indecies,
        [int(ds_size * train_perc), int(ds_size * (train_perc + val_perc)), ds_size],
    )
    return SplittedIndecies(train_indecies, validation_indecies, test_indecies)


def split_train_val_test(
    data: np.ndarray, labels: np.ndarray, train_perc: float, val_perc: float
) -> Tuple[SplittedDataset, Tuple[np.ndarray, np.ndarray, np.ndarray]]:
    assert len(data) == len(labels)
    train_indecies, validation_indecies, test_indecies = get_split_indecies(
        len(labels), train_perc, val_perc
    ).to_tuple()

    train_data, train_labels = data[train_indecies], labels[train_indecies]
    validation_data, validation_labels = data[validation_indecies], labels[validation_indecies]
    test_data, test_labels = data[test_indecies], labels[test_indecies]

    return SplittedDataset(
        DataLabelsPair(train_data, train_labels),
        DataLabelsPair(validation_data, validation_labels),
        DataLabelsPair(test_data, test_labels),
    ), SplittedIndecies(train_indecies, validation_indecies, test_indecies)
