from __future__ import annotations

import argparse
from pathlib import Path


CLASSES = ("crack", "dent", "leakage", "normal")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train a MobileNet defect classifier.")
    parser.add_argument("--dataset", type=Path, required=True, help="Dataset root with train/ and val/ folders.")
    parser.add_argument("--output", type=Path, default=Path("models/mobilenet_defects.pt"))
    parser.add_argument("--epochs", type=int, default=8)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--learning-rate", type=float, default=1e-4)
    return parser.parse_args()


def validate_dataset(dataset: Path) -> None:
    missing = []
    for split in ("train", "val"):
        for class_name in CLASSES:
            path = dataset / split / class_name
            if not path.exists():
                missing.append(path)
    if missing:
        lines = "\n".join(f"- {path}" for path in missing)
        raise SystemExit(f"Dataset is missing required folders:\n{lines}")


def main() -> None:
    args = parse_args()
    validate_dataset(args.dataset)

    try:
        import torch
        from torch import nn
        from torch.utils.data import DataLoader
        from torchvision import datasets, models, transforms
    except ImportError as exc:
        raise SystemExit(
            "PyTorch and torchvision are required for training. "
            "Install them separately from https://pytorch.org/get-started/locally/."
        ) from exc

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    transform = transforms.Compose(
        [
            transforms.Resize((224, 224)),
            transforms.RandomHorizontalFlip(),
            transforms.RandomRotation(8),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )
    val_transform = transforms.Compose(
        [
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )

    train_set = datasets.ImageFolder(args.dataset / "train", transform=transform)
    val_set = datasets.ImageFolder(args.dataset / "val", transform=val_transform)

    train_loader = DataLoader(train_set, batch_size=args.batch_size, shuffle=True, num_workers=2)
    val_loader = DataLoader(val_set, batch_size=args.batch_size, shuffle=False, num_workers=2)

    model = models.mobilenet_v3_small(weights=models.MobileNet_V3_Small_Weights.DEFAULT)
    model.classifier[-1] = nn.Linear(model.classifier[-1].in_features, len(train_set.classes))
    model = model.to(device)

    optimizer = torch.optim.AdamW(model.parameters(), lr=args.learning_rate)
    loss_fn = nn.CrossEntropyLoss()

    best_accuracy = 0.0
    args.output.parent.mkdir(parents=True, exist_ok=True)

    for epoch in range(1, args.epochs + 1):
        model.train()
        train_loss = 0.0
        for images, labels in train_loader:
            images = images.to(device)
            labels = labels.to(device)

            optimizer.zero_grad()
            logits = model(images)
            loss = loss_fn(logits, labels)
            loss.backward()
            optimizer.step()
            train_loss += loss.item() * images.size(0)

        model.eval()
        correct = 0
        total = 0
        with torch.no_grad():
            for images, labels in val_loader:
                images = images.to(device)
                labels = labels.to(device)
                logits = model(images)
                predictions = logits.argmax(dim=1)
                correct += (predictions == labels).sum().item()
                total += labels.size(0)

        accuracy = correct / max(total, 1)
        avg_loss = train_loss / max(len(train_set), 1)
        print(f"epoch={epoch} train_loss={avg_loss:.4f} val_accuracy={accuracy:.4f}")

        if accuracy >= best_accuracy:
            best_accuracy = accuracy
            checkpoint = {
                "class_to_idx": train_set.class_to_idx,
                "model_state": model.state_dict(),
                "accuracy": accuracy,
            }
            torch.save(checkpoint, args.output)
            print(f"saved checkpoint to {args.output}")


if __name__ == "__main__":
    main()
