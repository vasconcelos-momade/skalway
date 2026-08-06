import type { CentralSettingsRepository } from "../infrastructure/central-settings.repository";
import type { CentralSettingsDTO } from "../domain/central-settings.types";

export class GetCentralSettingsUseCase {
  constructor(private readonly repository: CentralSettingsRepository) {}

  async execute(): Promise<CentralSettingsDTO> {
    return this.repository.ensureSingleton();
  }
}
